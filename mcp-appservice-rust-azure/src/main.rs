use anyhow::Result;
use rmcp::{
    handler::server::{ServerHandler, tool::ToolRouter, wrapper::Parameters},
    model::{ServerCapabilities, ServerInfo},
    schemars, tool, tool_handler, tool_router,
    transport::streamable_http_server::{
        StreamableHttpServerConfig, StreamableHttpService,
        session::local::{LocalSessionManager, SessionConfig},
    },
};
use std::time::Duration;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

/// Request structure for the greeting tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
struct GetMsgRequest {
    /// The message to echo back
    #[schemars(description = "hello world")]
    pub message: String,
}

/// The main application state and handler for the MCP server
#[derive(Clone)]
struct HelloWorld {
    /// Router for MCP tools
    #[allow(dead_code)]
    tool_router: ToolRouter<Self>,
}

#[tool_router]
impl HelloWorld {
    /// Creates a new instance of the HelloWorld server handler
    fn new() -> Self {
        Self {
            tool_router: Self::tool_router(),
        }
    }

    /// Provides a greeting tool that echoes back a message
    #[tool(description = "Hello World via Model Context Protocol")]
    async fn greeting(
        &self,
        Parameters(GetMsgRequest { message }): Parameters<GetMsgRequest>,
    ) -> String {
        format!("Hello World MCP! {}", message)
    }
}

#[tool_handler]
impl ServerHandler for HelloWorld {
    fn get_info(&self) -> ServerInfo {
        ServerInfo::new(ServerCapabilities::builder().enable_tools().build())
            .with_instructions("A simple Hello World MCP")
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing subscriber for logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,mcp_aks_rust_azure=debug,rmcp=debug".into()),
        )
        .with(
            tracing_subscriber::fmt::layer()
                .with_writer(std::io::stderr)
                .pretty(),
        )
        .init();

    let service_factory = || Ok(HelloWorld::new());

    // Configure session manager with longer keep-alive
    let mut session_config = SessionConfig::default();
    session_config.keep_alive = Some(Duration::from_secs(3600)); // 1 hour session timeout
    let mut session_manager = LocalSessionManager::default();
    session_manager.session_config = session_config;

    // Configure allowed hosts for DNS rebinding protection
    let mut config = StreamableHttpServerConfig::default();
    config.sse_keep_alive = Some(Duration::from_secs(15)); // Explicit SSE keep-alive

    if let Ok(hosts_str) = std::env::var("ALLOWED_HOSTS") {
        tracing::info!("ALLOWED_HOSTS env set: {}", hosts_str);
        let hosts: Vec<String> = hosts_str.split(',').map(String::from).collect();
        if hosts.iter().any(|h| h == "*") {
            tracing::info!(
                "Wildcard '*' detected in ALLOWED_HOSTS, disabling check"
            );
            config.allowed_hosts = vec![];
        } else {
            config.allowed_hosts = hosts;
        }
    } else {
        // Default allowed hosts
        config.allowed_hosts = vec![
            "0.0.0.0".to_string(),
            "localhost".to_string(),
            "127.0.0.1".to_string(),
        ];
    }

    let service = StreamableHttpService::new(service_factory, session_manager.into(), config);

    // Add a specific health check route
    let app = axum::Router::new()
        .route("/health", axum::routing::get(|| async { "ok" }))
        .fallback_service(service);

    // Determine port from environment variable (Cloud Run standard)
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;

    tracing::info!("MCP Server listening on http://{}", addr);

    // Run with graceful shutdown
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

/// Handles graceful shutdown for SIGINT and SIGTERM
async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("Signal received, starting graceful shutdown...");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_greeting() {
        let hello = HelloWorld::new();
        let request = GetMsgRequest {
            message: "Tester".to_string(),
        };
        let response = hello.greeting(Parameters(request)).await;
        assert_eq!(response, "Hello World MCP! Tester");
    }
}
