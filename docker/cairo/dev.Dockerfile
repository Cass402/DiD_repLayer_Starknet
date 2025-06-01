# ==============================================================================
# Veridis Cairo Development Environment Dockerfile
# ==============================================================================
#
# This Dockerfile creates a comprehensive development environment for Cairo smart contracts
# on Starknet. It provides all necessary tools, compilers, and utilities for developing,
# testing, and deploying Cairo-based applications.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# 1. rust-base: Base Rust environment with system dependencies
# 2. cairo-tools: Cairo toolchain installation (Scarb, Foundry, Native)
# 3. dev-environment: Development environment setup with non-root user
# 4. final: Final optimized development image
#
# INCLUDED TOOLS & FRAMEWORKS:
# - Rust 1.87.0 toolchain with LLVM tools
# - Scarb (Cairo package manager)
# - Starknet Foundry (testing framework)
# - Cairo Native compiler
# - Node.js 22.x runtime
# - Python 3 with Cairo and Starknet libraries
# - Docker CLI for containerized workflows
# - Essential development utilities (git, vim, jq)
#
# SECURITY FEATURES:
# - Non-root user execution (vscode:1000)
# - Minimal attack surface with cleaned package caches
# - Proper file permissions and ownership
# - Health checks for tool availability
#
# BUILD ARGUMENTS:
# - SCARB_VERSION: Cairo package manager version (default: 2.11.4)
# - CAIRO_NATIVE_VERSION: Native compiler version (default: 2.11.4)
# - STARKNET_FOUNDRY_VERSION: Testing framework version (default: 0.44.0)
# - MLIR_OPTIMIZATION_LEVEL: Compiler optimization level (default: 3)
#
# USAGE:
# docker build -t veridis-cairo-dev .
# docker run -it -v $(pwd):/workspace veridis-cairo-dev
#
# WORKSPACE STRUCTURE:
# /workspace/
# ├── contracts/          # Cairo smart contract source files
# ├── tests/              # Test files and results
# ├── scripts/            # Build and deployment scripts
# └── security-scan-results/  # Security analysis outputs
#
# HEALTH MONITORING:
# - Automated health checks every 30 seconds
# - Validates all development tools functionality
# - Provides startup information display
#
# MAINTENANCE NOTES:
# - Based on Debian Bookworm for stability
# - Package versions are pinned for reproducibility
# - Regular security updates recommended
# - Compatible with VS Code dev containers
# ==============================================================================
# Stage 1: Base Rust environment with system dependencies
# ==============================================================================
FROM rust:1.87-slim-bookworm AS rust-base

# Install essential development tools and dependencies
# - curl: Command line tool for transferring data
# - git: Version control system
# - build-essential: Compilation tools (gcc, make, etc.)
# - pkg-config: Tool for retrieving library compile/link flags
# - libssl-dev: SSL/TLS development libraries
# - python3 & python3-pip: Python runtime and package manager
# - ca-certificates: Certificate authority certificates
# - gnupg: GNU Privacy Guard for encryption
# - lsb-release: Linux Standard Base release information
# - jq: JSON processor for command line
# - vim: Text editor
# - llvm-14: LLVM compiler infrastructure version 14
# - liblzma-dev: LZMA compression library development files
# - libclang-dev: Clang compiler development libraries
# Clean up apt cache to reduce image size
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    ca-certificates \
    gnupg \
    lsb-release \
    jq \
    vim \
    llvm-dev \
    liblzma-dev \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*


# Install Node.js version 22.x from the official NodeSource repository
# - Downloads and executes the NodeSource setup script for Node.js 22.x
# - Installs nodejs package using apt-get
# - Cleans up apt package lists to reduce image size
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Stage 2: Cairo toolchain installation
# ==============================================================================
FROM rust-base AS cairo-tools

# Build arguments for tool versions and optimization settings
# SCARB_VERSION: Version of Scarb (Cairo package manager) to install
# CAIRO_NATIVE_VERSION: Version of Cairo Native runtime to use
# STARKNET_FOUNDRY_VERSION: Version of Starknet Foundry testing framework to install
# MLIR_OPTIMIZATION_LEVEL: MLIR compiler optimization level (0-3, where 3 is highest)
#
# Environment variables are set from build arguments to make versions
# available throughout the container build process and at runtime
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG MLIR_OPTIMIZATION_LEVEL=3

ENV SCARB_VERSION=${SCARB_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}

# Install LLVM tools preview component for Rust toolchain
# This component provides additional LLVM-based tools like llvm-cov for code coverage
# and other debugging/profiling utilities required for Cairo development
RUN rustup component add llvm-tools-preview

# Install Scarb (Cairo package manager) using the official installation script
# Downloads and executes the install script from swmansion.com with the specified version
# Adds the Scarb binary location to the system PATH for global accessibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry using the official installation script
# Downloads and executes the install script from the foundry-rs repository
# Uses the version specified by the STARKNET_FOUNDRY_VERSION environment variable
# The script is piped to sh with version flag (-v) for specific version installation
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}

# Install Cairo Native compiler with the specified version
# Uses cargo to install from crates.io with locked dependencies to ensure reproducible builds
# The CAIRO_NATIVE_VERSION build argument must be defined earlier in the Dockerfile
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --locked

# Install Docker CLI in the container
# 1. Download and add Docker's official GPG key to the keyring
# 2. Add Docker's official APT repository to the sources list
# 3. Update package index and install Docker CLI
# 4. Clean up APT cache to reduce image size
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Stage 3: Development environment setup
# ==============================================================================
FROM cairo-tools AS dev-environment

# Install Cairo language tools and Starknet development dependencies
# - cairo-lang: Core Cairo language compiler and utilities
# - starknet-py: Python library for interacting with Starknet
# - starknet-devnet: Local Starknet development network for testing
RUN pip3 install --no-cache-dir cairo-lang starknet-py
RUN npm install -g starknet-devnet

# Create a non-root user 'vscode' with UID/GID 1000 for development environment
# - Creates vscode group with GID 1000
# - Creates vscode user with UID 1000, bash shell, and home directory
# - Creates necessary directories for Cairo, Scarb, and Cargo tools
# - Sets proper ownership of all created directories to vscode user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid vscode --shell /bin/bash --create-home vscode \
    && mkdir -p /home/vscode/.cairo /home/vscode/.local/share/scarb /home/vscode/.cargo \
    && chown -R vscode:vscode /home/vscode

# Copy Rust toolchain and Cargo from system-wide installation to vscode user's home directory
# This ensures the vscode user has access to Rust tools with proper ownership permissions
# - Copies rustup (Rust toolchain installer) to user's home
# - Copies cargo (Rust package manager) to user's home
# - Changes ownership of both directories to vscode user for proper access
RUN cp -r /usr/local/rustup /home/vscode/.rustup \
    && cp -r /usr/local/cargo /home/vscode/.cargo \
    && chown -R vscode:vscode /home/vscode/.rustup /home/vscode/.cargo

# Copy all binaries from root's local bin directory to vscode user's local bin directory
# Create the target directory if it doesn't exist and set proper ownership
# The 2>/dev/null || true ensures the command doesn't fail if source directory is empty
RUN mkdir -p /home/vscode/.local/bin && \
    if [ -d /root/.local/bin ] && [ "$(ls -A /root/.local/bin 2>/dev/null)" ]; then \
        cp -r /root/.local/bin/* /home/vscode/.local/bin/; \
    fi && \
    chown -R vscode:vscode /home/vscode/.local

# ==============================================================================
# Stage 4: Final development image
# ==============================================================================
FROM dev-environment AS final

# Set working directory
WORKDIR /workspace

# Create necessary workspace directories for Cairo development environment
# and set proper ownership for the vscode user to ensure write permissions
# Directories include:
# - security-scan-results: For storing security analysis outputs
# - contracts: For Cairo smart contract source files
# - tests: For test files and test results
# - scripts: For build and deployment scripts
RUN mkdir -p /workspace/security-scan-results \
    /workspace/contracts \
    /workspace/tests \
    /workspace/scripts \
    && chown -R vscode:vscode /workspace

# Switch to non-root user
USER vscode

# Set up environment variables for the development container
# PATH: Adds local binary directories and Cargo bin to the system PATH
# RUSTUP_HOME: Specifies the home directory for Rust toolchain management
# CARGO_HOME: Defines the directory where Cargo stores its files and cache
# CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL: Configures MLIR optimization level for Cairo native compilation
ENV PATH="/home/vscode/.local/bin:/home/vscode/.cargo/bin:${PATH}"
ENV RUSTUP_HOME="/home/vscode/.rustup"
ENV CARGO_HOME="/home/vscode/.cargo"
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}

# Health check setup for Cairo development environment
# Creates a health check script that verifies all essential development tools are installed and working:
# - scarb: Cairo package manager
# - snforge: Cairo testing framework
# - cairo-native: Native Cairo compiler
# - starknet-py: Python library for Starknet interaction
# - node: Node.js runtime
# The script is executed every 30 seconds with a 10-second timeout
# Container is considered healthy if all tools respond with version information
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Checking Cairo development tools..."\n\
scarb --version || exit 1\n\
snforge --version || exit 1\n\
cairo-native --version || exit 1\n\
python3 -c "import starknet_py; print(f\"starknet-py: {starknet_py.__version__}\")" || exit 1\n\
node --version || exit 1\n\
echo "All tools are working correctly!"\n\
' > /home/vscode/health-check.sh && chmod +x /home/vscode/health-check.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /home/vscode/health-check.sh


# Create and configure startup script that displays development environment information
# This script shows installed tool versions (Scarb, Starknet Foundry, Cairo Native, Node.js, Python)
# and provides a welcome message for the Veridis Cairo development environment.
# The script is made executable and will run any additional commands passed as arguments.
RUN echo '#!/bin/bash\n\
echo "🚀 Veridis Cairo Development Environment"\n\
echo "========================================"\n\
echo "Tools installed:"\n\
echo "  • Scarb: $(scarb --version)"\n\
echo "  • Starknet Foundry: $(snforge --version)"\n\
echo "  • Cairo Native: $(cairo-native --version)"\n\
echo "  • Node.js: $(node --version)"\n\
echo "  • Python: $(python3 --version)"\n\
echo ""\n\
echo "Ready for Cairo smart contract development! 🎯"\n\
echo ""\n\
exec "$@"\n\
' > /home/vscode/startup.sh && chmod +x /home/vscode/startup.sh


# Sets the default entry point for the container to execute the startup script
# located at /home/vscode/startup.sh when the container starts.
# The CMD instruction provides "bash" as the default argument to the entrypoint,
# allowing users to override it with custom commands while maintaining the
# startup script execution.
ENTRYPOINT ["/home/vscode/startup.sh"]

CMD ["bash"]


# Docker image labels for the Cairo development environment
# Provides metadata about the container including:
# - maintainer: Development team responsible for the image
# - version: Current version of the development environment
# - description: Brief explanation of the image purpose
# - org.opencontainers.image.source: Git repository URL following OCI standards
# - org.opencontainers.image.title: Human-readable image title
# - org.opencontainers.image.description: Detailed description of container capabilities
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Cairo smart contract development environment for Starknet" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Cairo Dev Environment" \
      org.opencontainers.image.description="Complete development environment for Cairo smart contracts"
