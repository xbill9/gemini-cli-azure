# Use a Rust image for building the application
# Using bullseye to match older GLIBC in Azure Functions base image
FROM rust:1.95-bullseye as builder

WORKDIR /app

# Copy Cargo.toml and Cargo.lock to leverage Docker cache for dependencies
COPY Cargo.toml Cargo.lock ./

# Copy the source code
COPY src ./src

# Build the application
RUN cargo build --release --locked --target x86_64-unknown-linux-gnu --jobs $(nproc)

# Use a minimal base image for the final stage
FROM mcr.microsoft.com/azure-functions/base:4

# Set environment variables for Azure Functions
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy the compiled binary from the builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-gnu/release/mcp-functions-rust-azure /home/site/wwwroot/mcp-functions-rust-azure

# Ensure the binary is executable
RUN chmod +x /home/site/wwwroot/mcp-functions-rust-azure

# Copy Azure Functions configuration files
COPY host.json /home/site/wwwroot/host.json
COPY mcp /home/site/wwwroot/mcp

# The Azure Functions base image handles the entrypoint and port (usually port 80)
EXPOSE 80
