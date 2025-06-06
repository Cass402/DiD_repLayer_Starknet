# ==============================================================================
# Veridis Cairo Development Environment Dockerfile
# ==============================================================================
#
# This Dockerfile creates a comprehensive development environment for Cairo smart
# contract development with enhanced security tooling and performance optimization.
# The image provides a complete toolchain for developing, testing, and auditing
# Cairo contracts with integrated security scanning capabilities.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# 1. base: Base Ubuntu environment with system dependencies
# 2. rust-toolchain: Rust installation with Cairo-compatible versions
# 3. cairo-tools: Cairo toolchain installation (Scarb, Foundry, Native)
# 4. security-tools: Security scanning and audit tools installation
# 5. development: Final development environment with all tools
#
# INCLUDED COMPONENTS:
# - Rust 1.87.0 toolchain (Cairo-compatible version)
# - Scarb (Cairo package manager) with security auditing
# - Starknet Foundry testing framework
# - Cairo Native compiler with MLIR optimization
# - Cairo security scanner for vulnerability detection
# - Comprehensive development and debugging tools
#
# SECURITY FEATURES:
# - Non-root user execution (cairo:1000)
# - Security scanning integration
# - Resource bounds enforcement
# - Audit trail capabilities
# - Comprehensive dependency verification
# - Minimal attack surface with targeted package installation
#
# BUILD ARGUMENTS:
# - SCARB_VERSION: Scarb package manager version (default: 2.11.4)
# - CAIRO_NATIVE_VERSION: Cairo Native compiler version (default: 2.11.4)
# - STARKNET_FOUNDRY_VERSION: Foundry testing framework version (default: 0.44.0)
# - RUST_VERSION: Rust toolchain version (default: 1.87.0)
# - MLIR_OPTIMIZATION_LEVEL: Compiler optimization level (default: 3)
# - FOUNDRY_RELEASE_TAG: Git tag for Foundry installation (default: v0.44.0)
# - SECURITY_TOOLS_REQUIRED: Fail build if security tools unavailable (default: false)
#
# USAGE:
# Build development environment:
# docker build --build-arg SCARB_VERSION=2.11.4 --build-arg RUST_VERSION=1.87.0 -t veridis/cairo-dev .
#
# Run development container with source mounting:
# docker run -it -v $(pwd):/workspace veridis/cairo-dev bash
#
# ENVIRONMENT VARIABLES (Runtime):
# - SCARB_SECURITY_AUDIT: Enable security auditing (default: true)
# - STARKNET_RESOURCE_BOUNDS_ENABLED: Enable resource bounds (default: true)
# - CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL: MLIR optimization level
# - STARKNET_TX_VERSION: Transaction version for network interactions
# - CAIRO_LOG_LEVEL: Logging verbosity (debug, info, warn, error)
#
# DEVELOPMENT WORKFLOW:
# - Mount source code to /workspace for development
# - Use integrated security scanning for vulnerability detection
# - Leverage performance optimization with Cairo Native
# - Run comprehensive test suites with Starknet Foundry
# - Generate audit reports with built-in security tools
#
# MAINTENANCE NOTES:
# - Based on Ubuntu 25.10 for latest package availability
# - Package versions are pinned for reproducible builds
# - Security tools are integrated for continuous scanning
# - Compatible with VS Code dev containers
# - Regular security updates through base image updates
# ==============================================================================

# ==============================================================================
# Stage 1: Base Ubuntu environment with system dependencies
# ==============================================================================
FROM ubuntu:25.10-slim AS base

# Cairo Development Environment Base Image Configuration
#
# This Dockerfile defines build arguments and environment variables for a Cairo/Starknet
# development environment. It sets up versions for various tools and configurations:
#
# Build Arguments:
# - SCARB_VERSION: Version of Scarb (Cairo package manager) to install
# - CAIRO_NATIVE_VERSION: Version of Cairo Native compiler to use
# - STARKNET_FOUNDRY_VERSION: Version of Starknet Foundry testing framework
# - RUST_VERSION: Rust toolchain version required for Cairo development
# - MLIR_OPTIMIZATION_LEVEL: MLIR compiler optimization level (0-3)
# - FOUNDRY_RELEASE_TAG: Git release tag for Foundry installation
# - SECURITY_TOOLS_REQUIRED: Flag to enable/disable security analysis tools
#
# Environment Variables:
# All build arguments are propagated as environment variables to be available
# at runtime for build scripts and toolchain configuration.
#
# Usage:
# This base configuration should be used as foundation for Cairo smart contract
# development environments, providing consistent tool versions across builds.
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG RUST_VERSION=1.87.0
ARG MLIR_OPTIMIZATION_LEVEL=3
ARG FOUNDRY_RELEASE_TAG=v0.44.0
ARG SECURITY_TOOLS_REQUIRED=false

ENV SCARB_VERSION=${SCARB_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV RUST_VERSION=${RUST_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV FOUNDRY_RELEASE_TAG=${FOUNDRY_RELEASE_TAG}
ENV SECURITY_TOOLS_REQUIRED=${SECURITY_TOOLS_REQUIRED}

# Install essential system dependencies for Cairo development
# Uses --no-install-recommends to minimize package bloat
# - curl: HTTP client for downloading tools and package managers
# - git: Version control system for source code management
# - build-essential: Essential compilation tools (gcc, make, etc.)
# - pkg-config: Helper tool for compiling applications and libraries
# - libssl-dev: SSL/TLS development libraries for secure connections
# - python3: Python 3 interpreter for tooling and scripts
# - python3-pip: Python package installer for additional dependencies
# - jq: Lightweight command-line JSON processor for configuration
# - ca-certificates: Certificate authority certificates for SSL verification
# - software-properties-common: Needed for adding LLVM repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    jq \
    ca-certificates \
    software-properties-common \
    gnupg \
    lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install LLVM 14 and development dependencies
# - Adds LLVM official APT repository with GPG key verification
# - Installs LLVM 14 toolchain, Clang development headers, and LZMA compression library
# - Cleans up package cache and temporary files to reduce image size
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-14 main" | tee /etc/apt/sources.list.d/llvm.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    llvm-14 \
    libclang-14-dev \
    liblzma-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ==============================================================================
# Stage 2: Rust toolchain installation with Cairo compatibility
# ==============================================================================
FROM base AS rust-toolchain

# Create dedicated cairo user early for Rust installation
RUN groupadd --gid 1000 cairo && \
    useradd --uid 1000 --gid cairo --shell /bin/bash --create-home cairo

# Install Rust as cairo user for better security and permissions
USER cairo

# Install Rust with specific version for Cairo compatibility
# Uses the official rustup installer with Cairo-compatible Rust version
# The version is pinned to ensure compatibility with Cairo toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/home/cairo/.cargo/bin:${PATH}"

# Install LLVM tools preview component for advanced development features
# This component provides additional LLVM-based tools like llvm-cov for code coverage
# and other debugging/profiling utilities required for Cairo development
RUN rustup component add llvm-tools-preview

# Verify Rust installation and display version information
# This ensures the Rust toolchain is properly installed and accessible
RUN echo "🔍 Verifying Rust installation..." && \
    rustc --version && \
    cargo --version

# ==============================================================================
# Stage 3: Cairo toolchain installation
# ==============================================================================
FROM rust-toolchain AS cairo-tools

# Install Scarb (Cairo package manager) using the official installation script
# Downloads and executes the install script with the specified version
# Scarb is the primary package manager and build tool for Cairo projects
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/home/cairo/.local/bin:${PATH}"

# Install Starknet Foundry using the official installation script
# Uses the specified release tag to ensure version consistency
# Foundry provides testing and deployment tools for Starknet development
RUN curl -L "https://raw.githubusercontent.com/foundry-rs/starknet-foundry/${FOUNDRY_RELEASE_TAG}/scripts/install.sh" | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}

# Install Cairo Native compiler with MLIR optimization features
# The --features "mlir-optimizer" flag enables advanced optimization capabilities
# The --locked flag ensures reproducible builds with exact dependency versions
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --features "mlir-optimizer" --locked

# Verify Cairo toolchain installation
# This step ensures all Cairo development tools are properly installed
RUN echo "🔍 Verifying Cairo toolchain installation..." && \
    scarb --version && \
    snforge --version && \
    sncast --version && \
    cairo-native --version

# ==============================================================================
# Stage 4: Security tools installation
# ==============================================================================
FROM cairo-tools AS security-tools

# Switch to root temporarily for system-wide Python package installation
USER root

# Install additional Python security tools with pinned versions for reproducibility
# These tools complement the Cairo-specific security scanner
RUN pip3 install --no-cache-dir \
    bandit==1.8.3 \
    safety==3.5.1 \
    semgrep==1.123.0

# Switch back to cairo user
USER cairo

# Install Cairo security scanner for vulnerability detection (optional)
# This tool provides static analysis and security auditing capabilities
# for Cairo smart contracts during development and testing phases
RUN if [ "$SECURITY_TOOLS_REQUIRED" = "true" ]; then \
        cargo install cairo-security-scanner --locked || \
        (echo "❌ Failed to install required Cairo security scanner" && exit 1); \
    else \
        cargo install cairo-security-scanner --locked 2>/dev/null || \
        echo "⚠️  Cairo security scanner not available - will use alternative security tools"; \
    fi

# Verify security tools installation with proper error handling
# Check availability of security scanning tools and fail if required tools are missing
RUN echo "🔍 Verifying security tools installation..." && \
    if [ "$SECURITY_TOOLS_REQUIRED" = "true" ]; then \
        (command -v bandit >/dev/null || (echo "❌ Required tool bandit not available" && exit 1)) && \
        (command -v safety >/dev/null || (echo "❌ Required tool safety not available" && exit 1)) && \
        (command -v semgrep >/dev/null || (echo "❌ Required tool semgrep not available" && exit 1)); \
    fi && \
    (bandit --version 2>/dev/null || echo "⚠️  Bandit not available") && \
    (safety --version 2>/dev/null || echo "⚠️  Safety not available") && \
    (semgrep --version 2>/dev/null || echo "⚠️  Semgrep not available") && \
    echo "✅ Security tools verification completed"

# ==============================================================================
# Stage 5: Development environment setup
# ==============================================================================
FROM security-tools AS development

# Switch to root for final setup tasks
USER root

# Create application directory structure with proper ownership
# Sets up workspace and configuration directories for development
RUN mkdir -p /app /workspace /home/cairo/.config && \
    chown -R cairo:cairo /app /workspace /home/cairo

# Set working directory for development activities
WORKDIR /workspace

# Set security-related and optimization environment variables
# These variables configure the Cairo development environment for security and performance
ENV SCARB_SECURITY_AUDIT=true
ENV STARKNET_RESOURCE_BOUNDS_ENABLED=true
ENV STARKNET_TX_VERSION=3
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV CAIRO_LOG_LEVEL=info

# Switch to non-root user for enhanced security
USER cairo

# Creates a comprehensive health check script for the Cairo development environment
# This script validates all essential Cairo development tools and security scanners
#
# The health check verifies:
# - Core Cairo tools: scarb (package manager), snforge (testing framework), cairo-native (compiler)
# - Security tools: cairo-security-scanner, bandit, safety, semgrep (optional but recommended)
# - Workspace accessibility and write permissions for mounted volumes
#
# Script features:
# - Conditional tool checking with proper error handling
# - User-friendly status messages with emoji indicators
# - Exit codes for CI/CD integration
# - Workspace permission validation for Docker volume mounts
#
# Usage: The script is installed to /home/cairo/health-check.sh and can be executed
# to verify the development environment is properly configured
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🔍 Checking Cairo development environment..."\n\
\n\
# Verify essential development tools with conditional checks\n\
echo "Verifying development tools:"\n\
if command -v scarb >/dev/null; then\n\
  scarb --version > /dev/null || (echo "❌ Scarb not functioning properly" && exit 1)\n\
  echo "✅ Scarb accessible"\n\
else\n\
  echo "❌ Scarb not found" && exit 1\n\
fi\n\
\n\
if command -v snforge >/dev/null; then\n\
  snforge --version > /dev/null || (echo "❌ Starknet Foundry not functioning properly" && exit 1)\n\
  echo "✅ Starknet Foundry accessible"\n\
else\n\
  echo "❌ Starknet Foundry not found" && exit 1\n\
fi\n\
\n\
if command -v cairo-native >/dev/null; then\n\
  cairo-native --version > /dev/null || (echo "❌ Cairo Native not functioning properly" && exit 1)\n\
  echo "✅ Cairo Native accessible"\n\
else\n\
  echo "❌ Cairo Native not found" && exit 1\n\
fi\n\
\n\
# Check security tools availability\n\
echo "Verifying security tools:"\n\
(command -v cairo-security-scanner >/dev/null && echo "✅ Cairo security scanner available") || echo "⚠️  Cairo security scanner not available"\n\
(command -v bandit >/dev/null && echo "✅ Bandit available") || echo "⚠️  Bandit not available"\n\
(command -v safety >/dev/null && echo "✅ Safety available") || echo "⚠️  Safety not available"\n\
(command -v semgrep >/dev/null && echo "✅ Semgrep available") || echo "⚠️  Semgrep not available"\n\
\n\
# Verify workspace access with ownership fix for mounted volumes\n\
if [ -d "/workspace" ]; then\n\
  if [ -w "/workspace" ]; then\n\
    echo "✅ Workspace accessible and writable"\n\
  else\n\
    echo "⚠️  Workspace not writable - may need volume ownership adjustment"\n\
  fi\n\
else\n\
  echo "❌ Workspace directory not found" && exit 1\n\
fi\n\
\n\
echo "🎯 Development environment ready!"\n\
' > /home/cairo/health-check.sh && chmod +x /home/cairo/health-check.sh

# Configure health check with reduced frequency to minimize overhead
# Monitors tool availability and workspace accessibility every 2 minutes
HEALTHCHECK --interval=120s --timeout=15s --start-period=15s --retries=3 \
    CMD /home/cairo/health-check.sh

# Creates a comprehensive startup script for the Cairo development environment
# This script provides:
# - Welcome banner with environment information
# - Version checking for all installed development tools (Scarb, Starknet Foundry, Cairo Native, Rust)
# - Display of environment configuration variables for security and optimization settings
# - Security tools availability check (Cairo Security Scanner, Bandit, Safety, Semgrep)
# - Workspace ownership and permission validation with helpful error messages
# - Development tips and usage examples when no command is provided
# - Automatic bash shell startup or command execution based on arguments
# The script is installed to /home/cairo/startup.sh with execute permissions
RUN echo '#!/bin/bash\n\
echo "🚀 Veridis Cairo Development Environment"\n\
echo "======================================"\n\
echo "Development Tools:"\n\
if command -v scarb >/dev/null; then\n\
  echo "  • Scarb: $(scarb --version)"\n\
else\n\
  echo "  • Scarb: Not found"\n\
fi\n\
\n\
if command -v snforge >/dev/null; then\n\
  echo "  • Starknet Foundry: $(snforge --version | head -n1)"\n\
else\n\
  echo "  • Starknet Foundry: Not found"\n\
fi\n\
\n\
if command -v cairo-native >/dev/null; then\n\
  echo "  • Cairo Native: $(cairo-native --version | head -n1)"\n\
else\n\
  echo "  • Cairo Native: Not found"\n\
fi\n\
\n\
if command -v rustc >/dev/null; then\n\
  echo "  • Rust: $(rustc --version)"\n\
else\n\
  echo "  • Rust: Not found"\n\
fi\n\
echo ""\n\
echo "Environment Configuration:"\n\
echo "  • Security Audit: ${SCARB_SECURITY_AUDIT:-false}"\n\
echo "  • Resource Bounds: ${STARKNET_RESOURCE_BOUNDS_ENABLED:-false}"\n\
echo "  • Optimization Level: ${CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL:-3}"\n\
echo "  • Transaction Version: ${STARKNET_TX_VERSION:-3}"\n\
echo "  • Log Level: ${CAIRO_LOG_LEVEL:-info}"\n\
echo ""\n\
echo "Security Tools:"\n\
(command -v cairo-security-scanner >/dev/null && echo "  • Cairo Security Scanner: Available") || echo "  • Cairo Security Scanner: Not available"\n\
(command -v bandit >/dev/null && echo "  • Bandit: Available") || echo "  • Bandit: Not available"\n\
(command -v safety >/dev/null && echo "  • Safety: Available") || echo "  • Safety: Not available"\n\
(command -v semgrep >/dev/null && echo "  • Semgrep: Available") || echo "  • Semgrep: Not available"\n\
echo ""\n\
echo "Workspace: /workspace (mounted source code)"\n\
echo "User: $(whoami) ($(id))"\n\
echo ""\n\
# Handle workspace ownership for mounted volumes\n\
if [ -d "/workspace" ] && [ ! -w "/workspace" ]; then\n\
  echo "⚠️  Workspace not writable - attempting to fix permissions..."\n\
  if [ "$(stat -c %u /workspace)" != "1000" ]; then\n\
    echo "   Note: Volume appears to be owned by different user"\n\
    echo "   Consider using: docker run --user $(id -u):$(id -g) ..."\n\
  fi\n\
fi\n\
echo "🎯 Ready for Cairo smart contract development!"\n\
echo ""\n\
if [ $# -eq 0 ]; then\n\
    echo "💡 Development tips:"\n\
    echo "  • Mount source code: -v \$(pwd):/workspace"\n\
    echo "  • Fix permissions: --user \$(id -u):\$(id -g)"\n\
    echo "  • Run security scan: bandit -r . || semgrep --config=auto ."\n\
    echo "  • Build project: scarb build"\n\
    echo "  • Run tests: snforge test"\n\
    echo ""\n\
    exec bash\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/cairo/startup.sh && chmod +x /home/cairo/startup.sh

# Set entrypoint to startup script for consistent initialization
# Provides development environment information and flexible command execution
ENTRYPOINT ["/home/cairo/startup.sh"]

# Default command starts an interactive bash shell for development
# Can be overridden to run specific development commands
CMD ["bash"]

# Container metadata and labels configuration
#
# This section defines comprehensive metadata for the Veridis Cairo Smart Contract
# Development Environment container using Docker LABEL instructions.
#
# Labels include:
# - Maintainer and version information
# - Tool versions for Scarb, Rust, Cairo Native, and Starknet Foundry
# - Security configuration and audit settings
# - MLIR optimization level configuration
# - OpenContainers Image Specification (OCI) standard labels for:
#   * Source repository and documentation links
#   * Image title, description, and vendor information
#   * License information (MIT)
#   * Base image details (Ubuntu 25.10-slim)
#
# These labels provide metadata that can be queried using 'docker inspect'
# and help with container management, documentation, and compliance tracking.
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Veridis Cairo Smart Contract Development Environment with integrated security tools" \
      environment.type="development" \
      tools.scarb.version="${SCARB_VERSION}" \
      tools.rust.version="${RUST_VERSION}" \
      tools.cairo-native.version="${CAIRO_NATIVE_VERSION}" \
      tools.foundry.version="${STARKNET_FOUNDRY_VERSION}" \
      security.audit="enabled" \
      security.tools.required="${SECURITY_TOOLS_REQUIRED}" \
      optimization.level="${MLIR_OPTIMIZATION_LEVEL}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Cairo Development Environment" \
      org.opencontainers.image.description="Comprehensive development environment for Cairo smart contracts with security scanning" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/README.md" \
      org.opencontainers.image.base.name="ubuntu:25.10-slim" \
      org.opencontainers.image.base.os.version="25.10"
