.PHONY: setup, fmt

setup:
	@echo "Setting up the project..."

fmt:
	cargo +nightly fmt
	git add .
	git commit -m "style: cargo fmt"