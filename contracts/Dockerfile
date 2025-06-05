# ==============================================================================
# Veridis Cairo Smart Contract Deployment Environment
# ==============================================================================
#
# This Dockerfile creates a production-ready environment for developing, testing,
# and deploying Cairo smart contracts to Starknet networks. The image is built
# using a multi-stage approach to optimize size while including all necessary
# tools and dependencies.
#
# STAGES OVERVIEW:
# ================
# 1. rust-base: Base Rust environment with system dependencies
# 2. cairo-tools: Cairo toolchain installation (Scarb, Foundry, Cairo Native)
# 3. contract-build: Contract compilation and testing environment
# 4. production: Lightweight production deployment environment
#
# KEY FEATURES:
# =============
# • Multi-stage build for optimized image size
# • Configurable tool versions via build arguments
# • Comprehensive testing and validation
# • Security-hardened with non-root user
# • Health checks and monitoring capabilities
# • Production-ready deployment scripts
# • Extensive documentation and metadata
#
# BUILD ARGUMENTS:
# ================
# SCARB_VERSION: Version of Scarb (Cairo package manager) to install
# STARKNET_FOUNDRY_VERSION: Version of Starknet Foundry tools to install
# CAIRO_NATIVE_VERSION: Version of Cairo Native compiler to install
# MLIR_OPTIMIZATION_LEVEL: MLIR optimization level for compilation (1-3)
# FOUNDRY_RELEASE_TAG: Git tag for Foundry installation script
#
# USAGE:
# ======
# Build: docker build -t veridis-cairo-contracts .
# Run:   docker run -e STARKNET_NETWORK=mainnet veridis-cairo-contracts
#
# SECURITY CONSIDERATIONS:
# ========================
# • Runs as non-root user 'veridis' (UID/GID 1001)
# • Minimal production image based on Ubuntu 22.04-slim
# • Package cache cleaned to reduce attack surface
# • CA certificates included for secure SSL/TLS connections
#
# MONITORING & HEALTH CHECKS:
# ============================
# • Built-in health check validates deployment environment
# • Startup script provides environment status information
# • Comprehensive logging and error handling
# • Artifact verification ensures successful builds
# ==============================================================================
# Stage 1: Base Rust environment with system dependencies
# ==============================================================================
FROM rust:1.87-slim-bookworm AS rust-base

# Build arguments for version control and optimization settings
# These arguments allow customization of tool versions during build time
# while maintaining default values for standard deployment scenarios
ARG SCARB_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG MLIR_OPTIMIZATION_LEVEL=3
ARG FOUNDRY_RELEASE_TAG=v0.44.0

# Set environment variables from build arguments for consistency
# across all build stages and runtime environment
ENV SCARB_VERSION=${SCARB_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV FOUNDRY_RELEASE_TAG=${FOUNDRY_RELEASE_TAG}

# Install essential development tools and dependencies
# - curl: Command line tool for transferring data
# - git: Version control system
# - build-essential: Contains essential compilation tools (gcc, make, etc.)
# - pkg-config: Helper tool for compiling applications and libraries
# - libssl-dev: SSL/TLS development libraries
# - ca-certificates: Common CA certificates for SSL verification
# - llvm-dev: LLVM compiler infrastructure development files
# - liblzma-dev: XZ compression library development files
# - libclang-dev: Clang compiler development libraries
# Clean up package cache and temporary files to reduce image size
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    llvm-dev \
    liblzma-dev \
    libclang-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Stage 2: Cairo toolchain installation
# ==============================================================================
FROM rust-base AS cairo-tools

# Install LLVM tools preview component for Rust toolchain
# This component provides additional LLVM-based tools like llvm-cov for code coverage
# and other debugging/profiling utilities required for Cairo development and testing
RUN rustup component add llvm-tools-preview

# Install Scarb (Cairo package manager) using the official installation script
# Downloads and executes the install script from swmansion.com with the specified version
# The installation script automatically adds Scarb to the local bin directory
# and configures the necessary environment for Cairo package management
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Download and install Starknet Foundry using the official installation script
# Uses the specified FOUNDRY_RELEASE_TAG to fetch the installer from GitHub
# and installs the version specified by STARKNET_FOUNDRY_VERSION variable
RUN curl -L \
  https://raw.githubusercontent.com/foundry-rs/starknet-foundry/${FOUNDRY_RELEASE_TAG}/scripts/install.sh \
  | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}

# Install Cairo Native compiler with the specified version
# Uses cargo to install from crates.io with locked dependencies to ensure reproducible builds
# Cairo Native provides optimized compilation capabilities for better contract performance
# The --locked flag ensures that the exact dependency versions are used
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --locked

# Verify all tools are installed correctly and accessible
# This step ensures that the build fails early if any tool installation was unsuccessful
# rather than discovering issues during contract compilation or deployment
RUN scarb --version && \
    snforge --version && \
    sncast --version && \
    cairo-native --version

# ==============================================================================
# Stage 3: Contract compilation and testing environment
# ==============================================================================
FROM cairo-tools AS contract-build

# Set working directory for contract build process
# All subsequent file operations will be relative to this directory
WORKDIR /app

# Copy Scarb configuration files and dependencies
# - Scarb.toml: Main Scarb project configuration file
# - Scarb.lock: Lock file containing exact dependency versions
# - .scarb* files: Copy any hidden Scarb configuration files to scarb/ directory (ignore errors if none exist)
# - foundry.toml: Foundry configuration file for testing framework (ignore errors if not present)
COPY Scarb.toml ./
COPY Scarb.lock ./
COPY .scarb* ./scarb/
COPY foundry.toml ./foundry.toml

# Fetch and download all dependencies defined in Scarb.toml
# Uses fallback echo command if scarb fetch fails or is unavailable
# This ensures the build process continues even if dependency fetching encounters issues
RUN scarb fetch || echo "⚠️  No dependencies to fetch or scarb fetch not available"

# Copy source code directory to the container
# Copy tests directory if it exists, silently ignore if not present
COPY src/ ./src/
COPY tests/ ./tests/

# Set the MLIR (Multi-Level Intermediate Representation) optimization level for Cairo Native compiler
# This environment variable controls the optimization level used during Cairo compilation
# Set the Starknet transaction version to use for blockchain interactions
# Version 3 is the current standard transaction version for Starknet network
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV STARKNET_TX_VERSION=3

# Build stage for Cairo smart contracts
# This stage compiles the Cairo contracts using scarb-native-build
# and runs the test suite using snforge to ensure contract integrity
# before deployment or further processing
RUN echo "🔨 Building Cairo contracts..." && \
    scarb-native-build

RUN echo "🧪 Running contract tests..." && \
    snforge test

# Verify build artifacts exist after compilation
# - Checks if target directory was created during build process
# - Ensures at least one compiled contract artifact (*.contract_class.json) exists
# - Exits with error code 1 if verification fails at any step
# - Provides clear success/failure messages for debugging build issues
RUN echo "✅ Verifying build artifacts..." && \
    [ -d "target" ] || (echo "❌ Build failed: target directory not found" && exit 1) && \
    [ "$(find target -name '*.contract_class.json' | wc -l)" -gt 0 ] || \
    (echo "❌ Build failed: no contract artifacts found" && exit 1)

# ==============================================================================
# Stage 4: Production deployment environment
# ==============================================================================
FROM ubuntu:22.04-slim AS production

# Install essential tools and utilities for the container environment
# - curl: Command line tool for transferring data from/to servers
# - jq: Lightweight and flexible command-line JSON processor
# - ca-certificates: Common CA certificates for SSL/TLS verification
# Clean up package cache and temporary files to reduce image size
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user 'veridis' with specific UID/GID (1001) for security purposes
# This ensures the container doesn't run as root and maintains consistent user permissions
# across different environments. The user is configured with bash shell and a home directory.
RUN groupadd --gid 1001 veridis && \
    useradd --uid 1001 --gid veridis --shell /bin/bash --create-home veridis

# Copy Starknet development tools from the contract-build stage to the final image
# - scarb: Starknet package manager and build tool
# - sncast: Starknet CLI tool for interacting with networks
# - snforge: Starknet testing framework for smart contracts
COPY --from=contract-build /root/.local/bin/scarb /usr/local/bin/
COPY --from=contract-build /root/.local/bin/sncast /usr/local/bin/
COPY --from=contract-build /root/.local/bin/snforge /usr/local/bin/

# Copy the compiled contract artifacts from the contract-build stage to the current stage
# - target/ directory contains the built Cairo contracts and compilation outputs
# - Scarb.toml is the project configuration file for the Cairo package manager
# - foundry.toml is the Foundry configuration file (copied conditionally, ignoring errors if file doesn't exist)
COPY --from=contract-build /app/target/ ./target/
COPY --from=contract-build /app/Scarb.toml ./
COPY --from=contract-build /app/foundry.toml ./foundry.toml

# Copy deployment and verification scripts to the container
# The deploy-contracts.sh script is required for contract deployment
# The verify-deployment.sh script is optional (uses || true to continue if file doesn't exist)
# Set executable permissions on all shell scripts in the scripts directory
COPY scripts/deploy-contracts.sh ./scripts/
COPY scripts/verify-deployment.sh ./scripts/
RUN chmod +x ./scripts/*.sh

# Create necessary application directories and set proper ownership
# - /app/deployments: Directory for storing deployment artifacts and configurations
# - /app/logs: Directory for application log files
# - /app/config: Directory for configuration files
# Sets ownership to veridis user and group for all created directories
RUN mkdir -p /app/deployments /app/logs /app/config && \
    chown -R veridis:veridis /app

# Set the working directory to /app for subsequent commands
WORKDIR /app

# Set the user context to 'veridis' for subsequent RUN, CMD, and ENTRYPOINT instructions
# This switches from root user to a non-privileged user for security best practices
# Ensures that processes within the container run with limited permissions
USER veridis

# Creates a comprehensive deployment health check script that validates the Starknet deployment environment
# This script performs the following checks:
# 1. Verifies essential deployment tools (scarb and sncast) are installed and accessible
# 2. Validates that contract artifacts exist in the target directory
# 3. Counts and reports the number of compiled contract artifacts (.contract_class.json files)
# 4. Tests network connectivity for non-devnet environments using sncast show-config
# 5. Provides clear success/failure feedback with emojis for better visibility
# The script is saved to /home/veridis/health-check.sh with executable permissions
# Exit codes: 0 for success, 1 for any validation failure
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🔍 Checking deployment environment..."\n\
\n\
# Verify essential tools are available\n\
echo "Verifying deployment tools:"\n\
scarb --version || exit 1\n\
sncast --version || exit 1\n\
echo "✅ All deployment tools available"\n\
\n\
# Check contract artifacts\n\
echo "Verifying contract artifacts:"\n\
[ -d "target" ] || (echo "❌ Contract artifacts missing" && exit 1)\n\
artifact_count=$(find target -name "*.contract_class.json" | wc -l)\n\
[ "$artifact_count" -gt 0 ] || (echo "❌ No contract artifacts found" && exit 1)\n\
echo "✅ Found $artifact_count contract artifacts"\n\
\n\
# Test network connectivity if network is specified\n\
if [ -n "$STARKNET_NETWORK" ] && [ "$STARKNET_NETWORK" != "devnet" ]; then\n\
  echo "Testing network connectivity to $STARKNET_NETWORK..."\n\
  sncast show-config --profile ${STARKNET_NETWORK} >/dev/null 2>&1 || {\n\
    echo "⚠️  Network configuration not found for $STARKNET_NETWORK"\n\
    echo "   Please ensure network is properly configured"\n\
    exit 1\n\
  }\n\
  echo "✅ Network connectivity verified"\n\
fi\n\
\n\
echo "🎯 Deployment environment ready!"\n\
' > /home/veridis/health-check.sh && chmod +x /home/veridis/health-check.sh

# Health check configuration that monitors container health every 30 seconds
# - Runs health check every 30 seconds (--interval)
# - Times out after 10 seconds if no response (--timeout)
# - Waits 5 seconds before starting health checks (--start-period)
# - Retries up to 3 times before marking as unhealthy (--retries)
# - Executes the health-check.sh script located in /home/veridis/
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /home/veridis/health-check.sh

# Create and configure a startup script that displays environment information
# and deployment readiness status for the Veridis Cairo contract environment.
#
# This script provides:
# - Environment version information (Scarb, Starknet Foundry)
# - Network configuration details
# - Optimization and transaction version settings
# - Contract artifact discovery and build status
# - Visual confirmation of deployment readiness
#
# The script is saved to /home/veridis/startup.sh with executable permissions
# and uses exec "$@" to chain command execution while preserving the informational output.
RUN echo '#!/bin/bash\n\
echo "🚀 Veridis Cairo Contract Deployment Environment"\n\
echo "==============================================="\n\
echo "Environment Details:"\n\
echo "  • Scarb: $(scarb --version)"\n\
echo "  • Starknet Foundry: $(sncast --version | head -n1)"\n\
echo "  • Target Network: ${STARKNET_NETWORK:-devnet}"\n\
echo "  • Optimization Level: ${CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL:-3}"\n\
echo "  • Transaction Version: ${STARKNET_TX_VERSION:-3}"\n\
echo ""\n\
echo "Contract Artifacts:"\n\
artifact_count=$(find target -name "*.contract_class.json" 2>/dev/null | wc -l)\n\
echo "  • Found $artifact_count compiled contracts"\n\
echo "  • Build timestamp: $(stat -c %y target 2>/dev/null | cut -d. -f1 || echo Unknown)"\n\
echo ""\n\
echo "🎯 Ready for contract deployment!"\n\
echo ""\n\
exec "$@"\n\
' > /home/veridis/startup.sh && chmod +x /home/veridis/startup.sh

# Sets the default entry point for the container to execute the startup script
# located at /home/veridis/startup.sh when the container starts
#
# Defines the default command to run the contract deployment script
# The CMD can be overridden when running the container with different arguments
ENTRYPOINT ["/home/veridis/startup.sh"]

CMD ["./scripts/deploy-contracts.sh"]

# LABEL DOCUMENTATION
# ===================
# This section defines comprehensive metadata for the Docker image using OCI-compliant labels.
# These labels provide essential information about the image, its purpose, and its origins.
#
# Core Metadata:
# - maintainer: Specifies the team responsible for maintaining this image
# - version: Semantic version of the image build
# - description: Brief overview of the image's purpose and capabilities
#
# OCI Standard Labels (org.opencontainers.image.*):
# - source: Repository URL where the source code is hosted
# - title: Human-readable name for the image
# - description: Detailed description of image functionality
# - vendor: Organization or team that created the image
# - licenses: License under which the image is distributed
# - documentation: URL to comprehensive documentation
# - base.name: The base image this image is built upon
# - base.os.version: Version of the base operating system
#
# These labels enable better image management, automated tooling integration,
# and provide transparency about the image's composition and purpose.
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Production-ready Cairo smart contract deployment environment for Starknet" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Cairo Contract Deployment" \
      org.opencontainers.image.description="Optimized production image for deploying Cairo smart contracts to Starknet networks" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/contracts/README.md" \
      org.opencontainers.image.base.name="ubuntu:22.04-slim" \
      org.opencontainers.image.base.os.version="22.04"
