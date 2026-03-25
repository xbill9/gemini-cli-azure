SUBDIRS := adkui-appservice \
	level_3-appservice \
	mcp-aca-python-azure \
	mcp-aci-python-azure \
	mcp-appservice-python-azure \
	mcp-fabric-python-azure \
	mcp-functions-python-azure \
	mcp-https-python-azure \
	mcp-stdio-python-azure \
	mcp-stdio-python-azurecli

.PHONY: list clean release az-destroy $(addprefix clean-,$(SUBDIRS)) $(addprefix release-,$(SUBDIRS)) $(addprefix az-destroy-,$(SUBDIRS))

list:
	@echo "Subdirectories:"
	@for dir in $(SUBDIRS); do \
		echo "  $$dir"; \
	done

clean: $(addprefix clean-,$(SUBDIRS))

release: $(addprefix release-,$(SUBDIRS))

az-destroy: $(addprefix az-destroy-,$(SUBDIRS))

define clean_task
clean-$(1):
	@echo "----------------------------------------------------------------"
	@echo "Cleaning $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		$(MAKE) -C $(1) clean || echo "Make clean failed or not defined in $(1), continuing..."; \
	elif [ -f "$(1)/Cargo.toml" ]; then \
		echo "Detected Rust project. Running cargo clean..."; \
		(cd $(1) && cargo clean); \
	elif [ -f "$(1)/go.mod" ]; then \
		echo "Detected Go project. Running go clean..."; \
		(cd $(1) && go clean); \
	elif [ -f "$(1)/package.json" ]; then \
		echo "Detected Node.js project. Removing node_modules and dist..."; \
		rm -rf $(1)/node_modules $(1)/dist; \
	else \
		echo "No build system detected for $(1). Skipping."; \
	fi
endef

define release_task
release-$(1):
	@echo "----------------------------------------------------------------"
	@echo "Releasing $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		$(MAKE) -C $(1) release || echo "Make release failed or not defined in $(1), continuing..."; \
	elif [ -f "$(1)/Cargo.toml" ]; then \
		echo "Detected Rust project. Running cargo build --release..."; \
		(cd $(1) && cargo build --release); \
	elif [ -f "$(1)/go.mod" ]; then \
		echo "Detected Go project. Running go build..."; \
		(cd $(1) && go build -v ./...); \
	elif [ -f "$(1)/package.json" ]; then \
		echo "Detected Node.js project. Running npm install && npm run build..."; \
		(cd $(1) && npm install && npm run build); \
	else \
		echo "No build system detected for $(1). Skipping."; \
	fi
endef

define az_destroy_task
az-destroy-$(1):
	@echo "----------------------------------------------------------------"
	@echo "Destroying Azure resources in $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		grep -q "az-destroy:" "$(1)/Makefile" && $(MAKE) -C $(1) az-destroy || echo "az-destroy target not found in $(1)/Makefile, skipping."; \
	else \
		echo "No Makefile found in $(1). Skipping."; \
	fi
endef

$(foreach dir,$(SUBDIRS),$(eval $(call clean_task,$(dir))))
$(foreach dir,$(SUBDIRS),$(eval $(call release_task,$(dir))))
$(foreach dir,$(SUBDIRS),$(eval $(call az_destroy_task,$(dir))))
