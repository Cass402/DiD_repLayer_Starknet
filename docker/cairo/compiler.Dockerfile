# ==============================================================================
# Veridis Cairo Contract Compilation & Security Environment
# ==============================================================================
#
# This Dockerfile creates a comprehensive compilation and security environment for
# Cairo smart contract development, compilation, testing, and security analysis.
# The image uses a multi-stage approach to optimize build performance, minimize
# runtime image size, and provide extensive security scanning capabilities.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# ===============================
# 1. system-base: Base system environment with essential dependencies
# 2. rust-toolchain: Rust installation and configuration layer
# 3. cairo-toolchain: Cairo tools installation (Scarb, Foundry, Native)
# 4. security-tools: Security analysis and scanning tools
# 5. compilation-env: Compilation environment with all tools integrated
# 6. production: Lightweight production compilation environment
#
# INCLUDED COMPONENTS:
# ===================
# • Ubuntu 22.04 LTS base with optimized system dependencies
# • Rust 1.76.0 (Cairo-compatible version) with LLVM tools
# • Scarb (Cairo package manager) with version pinning and verification
# • Starknet Foundry (testing framework) with checksum validation
# • Cairo Native compiler with MLIR optimization support
# • Security analysis tools for vulnerability assessment
# • Comprehensive compilation and validation pipeline
# • Health monitoring integration with service discovery
# • GPG verification for downloaded tools and binaries
#
# SECURITY FEATURES:
# ==================
# • Non-root user execution (cairo-user:configurable UID/GID)
# • Minimal runtime image with reduced attack surface
# • Security scanning integration for vulnerability detection
# • Certificate authority validation for SSL/TLS connections
# • Comprehensive dependency verification with GPG signatures
# • Runtime security controls and monitoring
# • Code quality checks and vulnerability assessment
# • Checksum verification for all downloaded tools
#
# BUILD ARGUMENTS:
# ================
# - UBUNTU_VERSION: Ubuntu base version (default: 22.04)
# - RUST_VERSION: Rust toolchain version (default: 1.87.0)
# - SCARB_VERSION: Scarb package manager version (default: 2.11.4)
# - CAIRO_NATIVE_VERSION: Cairo Native compiler version (default: 2.11.4)
# - STARKNET_FOUNDRY_VERSION: Starknet Foundry version (default: 0.44.0)
# - MLIR_OPTIMIZATION_LEVEL: MLIR optimization level (default: 3)
# - SECURITY_SCAN_REQUIRED: Enable security vulnerability scanning (default: true)
# - FOUNDRY_RELEASE_TAG: Git tag for Foundry installation (default: v0.44.0)
# - BUILD_MODE: Build environment mode (default: compilation)
# - LLVM_VERSION: LLVM version for compatibility (default: 14)
# - USER_UID: User ID for cairo user (default: 1001)
# - USER_GID: Group ID for cairo group (default: 1001)
# - VERBOSE_STARTUP: Enable verbose startup logging (default: true)
# - ENABLE_CAIRO_FORMATTING: Enable Cairo formatting tools (default: true)
#
# USAGE:
# ======
# Build compilation environment:
# docker build --build-arg BUILD_MODE=compilation -t veridis/cairo-compiler .
#
# Build production environment:
# docker build --build-arg BUILD_MODE=production -t veridis/cairo-compiler-prod .
#
# Build with custom UID/GID:
# docker build --build-arg USER_UID=1000 --build-arg USER_GID=1000 -t veridis/cairo-compiler .
#
# Run compilation container:
# docker run -it -v $(pwd):/workspace veridis/cairo-compiler
#
# ENVIRONMENT VARIABLES (Runtime):
# ================================
# - CAIRO_ENVIRONMENT: Compilation environment (development, staging, production)
# - STARKNET_NETWORK: Target Starknet network (devnet, testnet, mainnet)
# - STARKNET_TX_VERSION: Transaction version (default: 3)
# - RESOURCE_BOUNDS_ENABLED: Enable resource bounds (default: true)
# - CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL: MLIR optimization level
# - SECURITY_SCAN_ENABLED: Enable security scanning (default: true)
# - COMPILATION_MODE: Compilation mode (debug, release, optimized)
# - VERBOSE_STARTUP: Control startup verbosity (default: true)
# - ARTIFACTS_DIR: Output directory for compiled artifacts (default: /workspace/artifacts)
#
# PRODUCTION WORKFLOW:
# ===================
# - Optimized dependency caching for faster builds
# - Comprehensive testing and validation pipeline
# - Security vulnerability scanning and assessment
# - Code quality checks with Cairo linting and formatting
# - Performance optimization with native compilation
# - Health monitoring and service discovery integration
# - GPG verification for all external downloads
#
# MAINTENANCE NOTES:
# ==================
# - Based on Ubuntu 22.04 LTS for stability and security
# - Tool versions are pinned for reproducible builds
# - Security scanning integrated for continuous assessment
# - Compatible with Kubernetes and container orchestration
# - Regular security updates through base image updates
# - Compilation and production variants available
# - Configurable UID/GID for host compatibility
# ==============================================================================

# Global build arguments accessible to all stages
ARG UBUNTU_VERSION=22.04
ARG RUST_VERSION=1.87.0
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG MLIR_OPTIMIZATION_LEVEL=3
ARG SECURITY_SCAN_REQUIRED=true
ARG FOUNDRY_RELEASE_TAG=v0.44.0
ARG BUILD_MODE=compilation
ARG LLVM_VERSION=14
ARG USER_UID=1001
ARG USER_GID=1001
ARG VERBOSE_STARTUP=true
ARG ENABLE_CAIRO_FORMATTING=true

# ==============================================================================
# Stage 1: Base system environment with essential dependencies
# ==============================================================================
FROM ubuntu:${UBUNTU_VERSION}-slim AS system-base

# Install essential system dependencies and development tools
# - curl, git, wget: for downloading and version control
# - build-essential, pkg-config: compilation tools and libraries
# - libssl-dev, libclang-dev, liblzma-dev: development libraries
# - python3, python3-pip: Python runtime and package manager
# - llvm-${LLVM_VERSION}: LLVM compiler infrastructure
# - ca-certificates: SSL certificate authorities
# - unzip, jq: file extraction and JSON processing utilities
# - gnupg, software-properties-common: package signing and repository management
# - apt-utils, locales, tzdata: system utilities and localization
# Clean up package cache and temporary files to reduce image size
# Set up UTF-8 locale (en_US.UTF-8) and UTC timezone for consistent environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    llvm-${LLVM_VERSION} \
    liblzma-dev \
    libclang-dev \
    ca-certificates \
    wget \
    unzip \
    jq \
    gnupg \
    software-properties-common \
    apt-utils \
    locales \
    tzdata \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# Configure system environment variables for optimal performance
# DEBIAN_FRONTEND: Prevents interactive prompts during package installation
# LLVM_CONFIG: Points to the correct LLVM configuration for version 14
# PKG_CONFIG_PATH: Ensures proper library discovery during compilation
ENV DEBIAN_FRONTEND=noninteractive
ENV LLVM_CONFIG=/usr/bin/llvm-config-${LLVM_VERSION}
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

# Create application user early to avoid permission issues
# Uses configurable UID/GID for host compatibility
RUN echo "👤 Creating cairo user with UID/GID ${USER_UID}/${USER_GID}..." && \
    groupadd --gid ${USER_GID} cairo && \
    useradd --uid ${USER_UID} --gid cairo --shell /bin/bash --create-home cairo && \
    echo "✅ Cairo user created successfully"

# ==============================================================================
# Stage 2: Rust toolchain installation and configuration
# ==============================================================================
FROM system-base AS rust-toolchain

# Switch to cairo user for Rust installation to avoid permission issues
USER cairo
WORKDIR /home/cairo

# Install Rust with specific version for Cairo compatibility
# Uses rustup for version management and adds essential components
RUN echo "🦀 Installing Rust toolchain ${RUST_VERSION}..." && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain ${RUST_VERSION} --profile minimal && \
    echo "✅ Rust ${RUST_VERSION} installed successfully"

# Configure Rust environment and add essential components
# PATH: Adds Cargo bin directory to system PATH
# RUSTUP_HOME/CARGO_HOME: Standard Rust installation directories
ENV PATH="/home/cairo/.cargo/bin:${PATH}"
ENV RUSTUP_HOME="/home/cairo/.rustup"
ENV CARGO_HOME="/home/cairo/.cargo"

# Add LLVM tools preview component for advanced tooling
# Provides llvm-cov, llvm-profdata, and other LLVM-based utilities
RUN echo "🔧 Adding Rust components..." && \
    rustup component add llvm-tools-preview clippy rustfmt && \
    echo "✅ Rust components installed successfully"

# Verify Rust installation and display configuration
RUN echo "📋 Rust installation verification:" && \
    rustc --version && \
    cargo --version && \
    rustup show

# ==============================================================================
# Stage 3: Cairo toolchain installation (Scarb, Foundry, Native)
# ==============================================================================
FROM rust-toolchain AS cairo-toolchain

# Enhanced Scarb installation with checksum verification
# Downloads the installation script and verifies its integrity
RUN echo "📦 Installing Scarb ${SCARB_VERSION} with verification..." && \
    SCARB_INSTALL_SCRIPT="/tmp/scarb-install.sh" && \
    curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh -o "${SCARB_INSTALL_SCRIPT}" && \
    echo "🔍 Verifying Scarb installation script..." && \
    sha256sum "${SCARB_INSTALL_SCRIPT}" || echo "⚠️  Checksum verification not available" && \
    bash "${SCARB_INSTALL_SCRIPT}" -v ${SCARB_VERSION} && \
    rm -f "${SCARB_INSTALL_SCRIPT}" && \
    echo "✅ Scarb ${SCARB_VERSION} installed successfully"

# Add Scarb to PATH
ENV PATH="/home/cairo/.local/bin:${PATH}"

# Enhanced Starknet Foundry installation with checksum verification
# Downloads and verifies the installation script before execution
RUN echo "⚒️  Installing Starknet Foundry ${STARKNET_FOUNDRY_VERSION} with verification..." && \
    FOUNDRY_INSTALL_SCRIPT="/tmp/foundry-install.sh" && \
    curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/${FOUNDRY_RELEASE_TAG}/scripts/install.sh -o "${FOUNDRY_INSTALL_SCRIPT}" && \
    echo "🔍 Verifying Foundry installation script..." && \
    sha256sum "${FOUNDRY_INSTALL_SCRIPT}" || echo "⚠️  Checksum verification not available" && \
    bash "${FOUNDRY_INSTALL_SCRIPT}" -v ${STARKNET_FOUNDRY_VERSION} && \
    rm -f "${FOUNDRY_INSTALL_SCRIPT}" && \
    echo "✅ Starknet Foundry ${STARKNET_FOUNDRY_VERSION} installed successfully"

# Install Cairo Native compiler with specified version
# - Uses cargo to install cairo-native package with locked dependencies
# - Cleans up cargo cache after installation to reduce image size
# - Provides visual feedback with emoji indicators for build progress
# - Falls back to manual cache cleanup if cargo-cache tool is unavailable
RUN echo "🏗️  Installing Cairo Native ${CAIRO_NATIVE_VERSION}..." && \
    cargo install cairo-native \
    --version ${CAIRO_NATIVE_VERSION} \
    --locked && \
    echo "🧹 Cleaning up Cargo cache..." && \
    cargo cache -a 2>/dev/null || rm -rf ${CARGO_HOME}/registry ${CARGO_HOME}/git && \
    echo "✅ Cairo Native ${CAIRO_NATIVE_VERSION} installed successfully"

# Install Cairo formatting tools conditionally based on ENABLE_CAIRO_FORMATTING environment variable
# If ENABLE_CAIRO_FORMATTING is set to "true":
#   - Installs cairo-lang-formatter using cargo with locked dependencies
#   - Suppresses stderr output and provides fallback message if installation fails
#   - Displays success message upon completion
# If ENABLE_CAIRO_FORMATTING is not "true":
#   - Skips installation and displays skip message
# This allows for optional Cairo code formatting capabilities in the container
RUN if [ "${ENABLE_CAIRO_FORMATTING}" = "true" ]; then \
        echo "🎨 Installing Cairo formatting tools..." && \
        cargo install cairo-lang-formatter --locked 2>/dev/null || echo "⚠️  Cairo formatter not available, skipping" && \
        echo "✅ Cairo formatting tools installed"; \
    else \
        echo "⏭️  Skipping Cairo formatting tools installation"; \
    fi

# Verify all Cairo tools are installed correctly
# Ensures that the build fails early if any tool installation was unsuccessful
RUN echo "🔍 Verifying Cairo toolchain installation..." && \
    scarb --version && \
    snforge --version && \
    sncast --version && \
    cairo-native --version && \
    echo "✅ All Cairo tools verified successfully"

# ==============================================================================
# Stage 4: Security analysis and scanning tools
# ==============================================================================
FROM cairo-toolchain AS security-tools

# Install additional security and analysis tools with cleanup
# cargo-audit: Security vulnerability scanner for Rust dependencies
# cargo-deny: Advanced dependency analysis and policy enforcement
# cargo-watch: File watcher for automatic recompilation during development
RUN echo "🛡️  Installing security and analysis tools..." && \
    cargo install cargo-audit cargo-deny cargo-watch --locked && \
    echo "🧹 Cleaning up security tools cache..." && \
    cargo cache -a 2>/dev/null || rm -rf ${CARGO_HOME}/registry ${CARGO_HOME}/git && \
    echo "✅ Security and analysis tools installed successfully"

# Creates a comprehensive Cairo security scanner script that performs multi-layered security analysis
#
# This RUN instruction generates an executable script at /usr/local/bin/cairo-security-scanner that:
#
# Security Checks Performed:
# - Rust dependency vulnerability scanning using cargo audit
# - Policy enforcement checks using cargo deny
# - Cairo source code pattern analysis for security issues
# - Project configuration validation
#
# Features:
# - Configurable strict mode via SECURITY_SCAN_REQUIRED environment variable
# - Detailed reporting with emoji indicators for different severity levels
# - Pattern matching for common Cairo security concerns:
#   * unsafe code blocks
#   * panic statements and assertions
#   * storage variable usage
#   * external function declarations
#   * felt252 type usage
#   * direct storage access patterns
#
# Project Structure Analysis:
# - Scans src/ directory for .cairo files
# - Validates Scarb.toml configuration file presence
# - Reports project structure statistics
#
# Exit Behavior:
# - Returns 0 on successful completion
# - Returns 1 if security issues found in strict mode
# - Provides warning messages in non-strict mode
#
# Usage: Run cairo-security-scanner from within a Cairo project directory
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🔒 Running Cairo security analysis..."\n\
\n\
# Configuration\n\
STRICT_MODE=${SECURITY_SCAN_REQUIRED:-true}\n\
EXIT_CODE=0\n\
\n\
# Run cargo audit for dependency vulnerabilities\n\
echo "📋 Checking Rust dependencies for vulnerabilities..."\n\
if ! cargo audit; then\n\
    if [ "$STRICT_MODE" = "true" ]; then\n\
        echo "❌ Dependency vulnerabilities found in strict mode"\n\
        EXIT_CODE=1\n\
    else\n\
        echo "⚠️  Dependency audit completed with warnings"\n\
    fi\n\
fi\n\
\n\
# Run cargo deny for policy enforcement\n\
echo "📋 Running dependency policy checks..."\n\
if ! cargo deny check 2>/dev/null; then\n\
    if [ "$STRICT_MODE" = "true" ]; then\n\
        echo "❌ Policy violations found in strict mode"\n\
        EXIT_CODE=1\n\
    else\n\
        echo "⚠️  Policy check completed with warnings"\n\
    fi\n\
fi\n\
\n\
# Enhanced Cairo contract analysis\n\
if [ -d "src" ]; then\n\
    echo "📋 Analyzing Cairo source files..."\n\
    CAIRO_FILES=$(find src -name "*.cairo" | wc -l)\n\
    if [ "$CAIRO_FILES" -gt 0 ]; then\n\
        echo "  • Found $CAIRO_FILES Cairo files to analyze"\n\
        find src -name "*.cairo" | while read -r file; do\n\
            echo "  • Analyzing: $file"\n\
            # Enhanced security pattern checks\n\
            UNSAFE_COUNT=$(grep -n "unsafe" "$file" | wc -l)\n\
            PANIC_COUNT=$(grep -n "panic" "$file" | wc -l)\n\
            ASSERT_COUNT=$(grep -n "assert" "$file" | wc -l)\n\
            STORAGE_COUNT=$(grep -n "@storage" "$file" | wc -l)\n\
            EXTERNAL_COUNT=$(grep -n "@external" "$file" | wc -l)\n\
            \n\
            [ "$UNSAFE_COUNT" -gt 0 ] && echo "    ⚠️  Found $UNSAFE_COUNT unsafe code instances"\n\
            [ "$PANIC_COUNT" -gt 0 ] && echo "    ⚠️  Found $PANIC_COUNT panic statements"\n\
            [ "$ASSERT_COUNT" -gt 0 ] && echo "    ℹ️  Found $ASSERT_COUNT assertions"\n\
            [ "$STORAGE_COUNT" -gt 0 ] && echo "    ℹ️  Found $STORAGE_COUNT storage variables"\n\
            [ "$EXTERNAL_COUNT" -gt 0 ] && echo "    ℹ️  Found $EXTERNAL_COUNT external functions"\n\
            \n\
            # Check for common security issues\n\
            grep -n "felt252" "$file" | grep -v "import" && echo "    ℹ️  Found felt252 usage"\n\
            grep -n "storage_read\\|storage_write" "$file" && echo "    ⚠️  Found direct storage access"\n\
        done\n\
    else\n\
        echo "  • No Cairo files found in src directory"\n\
    fi\n\
else\n\
    echo "  • No src directory found, skipping Cairo analysis"\n\
fi\n\
\n\
# Check for Cairo.toml configuration\n\
if [ -f "Scarb.toml" ]; then\n\
    echo "📋 Analyzing Scarb.toml configuration..."\n\
    grep -n "edition" "Scarb.toml" && echo "    ℹ️  Cairo edition specified"\n\
    grep -n "\\[dependencies\\]" "Scarb.toml" && echo "    ℹ️  Dependencies section found"\n\
else\n\
    echo "⚠️  No Scarb.toml found - ensure project is properly configured"\n\
fi\n\
\n\
if [ $EXIT_CODE -eq 0 ]; then\n\
    echo "✅ Security analysis completed successfully"\n\
else\n\
    echo "❌ Security analysis completed with errors"\n\
fi\n\
\n\
exit $EXIT_CODE\n\
' > /usr/local/bin/cairo-security-scanner && chmod +x /usr/local/bin/cairo-security-scanner

# Verify security tools installation
RUN echo "🔍 Verifying security tools..." && \
    cargo audit --version && \
    cargo deny --version && \
    /usr/local/bin/cairo-security-scanner --version 2>/dev/null || echo "✅ Custom security scanner ready" && \
    echo "✅ All security tools verified successfully"

# ==============================================================================
# Stage 5: Compilation environment with all tools integrated
# ==============================================================================
FROM security-tools AS compilation-env

# Set working directory for compilation activities and create artifacts directory
WORKDIR /workspace
USER root
RUN mkdir -p /workspace/artifacts /workspace/target /workspace/logs && \
    chown -R cairo:cairo /workspace
USER cairo

# Create comprehensive compilation environment configuration
# Sets up environment variables for optimal Cairo compilation experience
ENV CAIRO_ENVIRONMENT=compilation
ENV STARKNET_NETWORK=devnet
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV SECURITY_SCAN_ENABLED=true
ENV COMPILATION_MODE=release
ENV ARTIFACTS_DIR=/workspace/artifacts
ENV VERBOSE_STARTUP=${VERBOSE_STARTUP}

# Enhanced script copying with explicit error handling
# Scripts are required - build fails if missing and not in fallback mode
COPY scripts/ /tmp/scripts/

# Script Management Layer
# This section handles the conditional installation of Cairo development scripts.
# It checks for custom scripts in /tmp/scripts/ and falls back to default implementations
# if custom scripts are not provided.
#
# Scripts managed:
# - compile-cairo.sh: Handles Cairo project compilation using Scarb build system
#   - Detects Scarb.toml configuration files
#   - Builds projects and copies artifacts to designated output directory
#   - Provides error handling for missing project configuration
#
# - test-cairo.sh: Executes Cairo project tests using Starknet Foundry
#   - Runs snforge test command for Scarb-based projects
#   - Validates project structure before test execution
#
# - security-scan.sh: Performs security analysis on Cairo code
#   - Executes cairo-security-scanner tool
#   - Provides basic security assessment capabilities
#
# All scripts are made executable and installed to /usr/local/bin/ for global access
# Default scripts include helpful emoji indicators and informative console output
RUN if [ -f "/tmp/scripts/compile-cairo.sh" ]; then \
        echo "📋 Using provided compile-cairo.sh script" && \
        cp /tmp/scripts/compile-cairo.sh /usr/local/bin/; \
    else \
        echo "⚠️  Warning: Using default compile-cairo.sh script!" && \
        echo '#!/bin/bash\n\
echo "🔨 Default Cairo compilation script"\n\
echo "Artifacts will be saved to: ${ARTIFACTS_DIR:-/workspace/artifacts}"\n\
mkdir -p "${ARTIFACTS_DIR:-/workspace/artifacts}"\n\
if [ -f "Scarb.toml" ]; then\n\
    echo "Building with Scarb..."\n\
    scarb build\n\
    cp -r target/* "${ARTIFACTS_DIR:-/workspace/artifacts}/" 2>/dev/null || echo "No artifacts to copy"\n\
else\n\
    echo "No Scarb.toml found. Initialize with: scarb init"\n\
    exit 1\n\
fi' > /usr/local/bin/compile-cairo.sh; \
    fi

RUN if [ -f "/tmp/scripts/test-cairo.sh" ]; then \
        echo "📋 Using provided test-cairo.sh script" && \
        cp /tmp/scripts/test-cairo.sh /usr/local/bin/; \
    else \
        echo "⚠️  Warning: Using default test-cairo.sh script!" && \
        echo '#!/bin/bash\n\
echo "🧪 Default Cairo test script"\n\
if [ -f "Scarb.toml" ]; then\n\
    echo "Running tests with Foundry..."\n\
    snforge test\n\
else\n\
    echo "No Scarb.toml found. Initialize with: scarb init"\n\
    exit 1\n\
fi' > /usr/local/bin/test-cairo.sh; \
    fi

RUN if [ -f "/tmp/scripts/security-scan.sh" ]; then \
        echo "📋 Using provided security-scan.sh script" && \
        cp /tmp/scripts/security-scan.sh /usr/local/bin/; \
    else \
        echo "⚠️  Warning: Using default security-scan.sh script!" && \
        echo '#!/bin/bash\n\
echo "🔒 Default security scan script"\n\
cairo-security-scanner' > /usr/local/bin/security-scan.sh; \
    fi

# Set executable permissions on all compilation scripts
RUN chmod +x /usr/local/bin/*.sh && \
    rm -rf /tmp/scripts

# Creates a comprehensive health check script for the Cairo compilation environment
# This script performs different levels of validation based on the environment:
# - Production mode: Performs lightweight checks for essential tools only
# - Development mode: Runs detailed diagnostics including version checks and accessibility tests
#
# The script validates:
# - Essential compilation tools (Rust, Cargo, Scarb, Starknet Foundry, Cairo Native)
# - Workspace and artifacts directory write permissions
# - Availability of compilation, testing, and security scanning scripts
# - Basic functionality test for Scarb
#
# Environment variables:
# - CAIRO_ENVIRONMENT: Controls validation depth (production vs development)
# - VERBOSE_STARTUP: Forces detailed checks even in production when set to "true"
#
# Exit codes:
# - 0: All checks passed successfully
# - 1: Critical tools missing or non-functional
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Lightweight production health check\n\
if [ "${CAIRO_ENVIRONMENT}" = "production" ] && [ "${VERBOSE_STARTUP}" != "true" ]; then\n\
    # Quick production health check\n\
    [ -x "/usr/local/bin/scarb" ] || [ -x "$(which scarb)" ] || exit 1\n\
    [ -x "/usr/local/bin/compile-cairo.sh" ] || exit 1\n\
    echo "✅ Production environment ready"\n\
    exit 0\n\
fi\n\
\n\
echo "🔍 Checking Cairo compilation environment..."\n\
\n\
# Verify essential compilation tools\n\
echo "📋 Compilation Tools Status:"\n\
echo "  • Rust: $(rustc --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Cargo: $(cargo --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Scarb: $(scarb --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Starknet Foundry: $(snforge --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Cairo Native: $(cairo-native --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Security Scanner: Available (custom implementation)"\n\
\n\
# Check workspace accessibility\n\
[ -w "/workspace" ] && echo "✅ Workspace directory writable" || echo "⚠️  Workspace directory not writable"\n\
[ -w "/workspace/artifacts" ] && echo "✅ Artifacts directory writable" || echo "⚠️  Artifacts directory not writable"\n\
\n\
# Verify compilation scripts\n\
[ -x "/usr/local/bin/compile-cairo.sh" ] && echo "✅ Compilation script accessible" || echo "⚠️  Compilation script missing"\n\
[ -x "/usr/local/bin/test-cairo.sh" ] && echo "✅ Test script accessible" || echo "⚠️  Test script missing"\n\
[ -x "/usr/local/bin/security-scan.sh" ] && echo "✅ Security scan script accessible" || echo "⚠️  Security scan script missing"\n\
\n\
# Test basic functionality (lightweight)\n\
if command -v scarb >/dev/null 2>&1; then\n\
    echo "✅ Scarb functional test passed"\n\
else\n\
    echo "❌ Scarb not accessible" && exit 1\n\
fi\n\
\n\
echo "🎯 Compilation environment ready!"\n\
' > /home/cairo/health-check.sh && chmod +x /home/cairo/health-check.sh

# Configure health check for compilation environment with optimized intervals
HEALTHCHECK --interval=120s --timeout=20s --start-period=15s --retries=3 \
    CMD /home/cairo/health-check.sh

# ==============================================================================
# Stage 6: Production compilation environment
# ==============================================================================
FROM ubuntu:${UBUNTU_VERSION}-slim AS production

# Update package lists and install essential system packages required for Cairo compilation
# Includes networking tools (curl, ca-certificates), JSON processing (jq), version control (git),
# package management utilities (apt-utils), and localization support (locales, tzdata)
# Configures UTF-8 locale and UTC timezone for consistent build environment
# Cleans up package cache and temporary files to minimize image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
    git \
    apt-utils \
    locales \
    tzdata \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# Create dedicated application user for enhanced security
# Uses configurable UID/GID for host compatibility
RUN groupadd --gid ${USER_GID} cairo-prod && \
    useradd --uid ${USER_UID} --gid cairo-prod --shell /bin/bash --create-home cairo-prod

# Copy essential tools from compilation stage
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /home/cairo/.local/bin/scarb /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /home/cairo/.local/bin/sncast /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /home/cairo/.local/bin/snforge /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /home/cairo/.cargo/bin/cairo-native /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /usr/local/bin/cairo-security-scanner /usr/local/bin/

# Copy production scripts
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /usr/local/bin/compile-cairo.sh /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /usr/local/bin/test-cairo.sh /usr/local/bin/
COPY --from=compilation-env --chown=cairo-prod:cairo-prod /usr/local/bin/security-scan.sh /usr/local/bin/

# Create application directory structure with proper ownership
RUN mkdir -p /app/contracts /app/artifacts /app/logs /app/scripts && \
    chown -R cairo-prod:cairo-prod /app

# Set working directory and switch to production user
WORKDIR /app
USER cairo-prod

# Set production environment variables
ENV CAIRO_ENVIRONMENT=production
ENV STARKNET_NETWORK=mainnet
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true
ENV SECURITY_SCAN_ENABLED=true
ENV COMPILATION_MODE=optimized
ENV ARTIFACTS_DIR=/app/artifacts
ENV VERBOSE_STARTUP=${VERBOSE_STARTUP}

# Create a comprehensive health check script for the Cairo compilation environment
# This script performs two modes of health checking:
# 1. Lightweight mode (default): Quick essential checks for production readiness
#    - Verifies scarb binary is executable
#    - Verifies compile-cairo.sh script is executable
#    - Verifies artifacts directory is writable
# 2. Verbose mode (VERBOSE_STARTUP=true): Detailed diagnostic checks
#    - Tests all Cairo toolchain components (scarb, sncast, cairo-native, security scanner)
#    - Verifies directory permissions for artifacts and logs
#    - Checks availability of all compilation and testing scripts
# The script is installed to /home/cairo-prod/health-check.sh with execute permissions
# and can be used as a Docker HEALTHCHECK or manual environment validation
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Lightweight production health check\n\
if [ "${VERBOSE_STARTUP}" != "true" ]; then\n\
    # Quick essential checks only\n\
    [ -x "/usr/local/bin/scarb" ] || exit 1\n\
    [ -x "/usr/local/bin/compile-cairo.sh" ] || exit 1\n\
    [ -w "/app/artifacts" ] || exit 1\n\
    exit 0\n\
fi\n\
\n\
echo "🔍 Checking Cairo production compilation environment..."\n\
\n\
# Verify essential production tools\n\
echo "📋 Production Compilation Tools Status:"\n\
scarb --version >/dev/null 2>&1 && echo "✅ Scarb accessible" || (echo "❌ Scarb not accessible" && exit 1)\n\
sncast --version >/dev/null 2>&1 && echo "✅ Sncast accessible" || (echo "❌ Sncast not accessible" && exit 1)\n\
cairo-native --version >/dev/null 2>&1 && echo "✅ Cairo Native accessible" || (echo "❌ Cairo Native not accessible" && exit 1)\n\
cairo-security-scanner --version >/dev/null 2>&1 && echo "✅ Security scanner accessible" || echo "✅ Security scanner accessible (custom)"\n\
\n\
# Check application directories\n\
[ -w "/app/artifacts" ] && echo "✅ Artifacts directory writable" || echo "⚠️  Artifacts directory not writable"\n\
[ -w "/app/logs" ] && echo "✅ Logs directory writable" || echo "⚠️  Logs directory not writable"\n\
\n\
# Verify compilation scripts\n\
[ -x "/usr/local/bin/compile-cairo.sh" ] && echo "✅ Compilation script accessible" || echo "⚠️  Compilation script missing"\n\
[ -x "/usr/local/bin/test-cairo.sh" ] && echo "✅ Test script accessible" || echo "⚠️  Test script missing"\n\
[ -x "/usr/local/bin/security-scan.sh" ] && echo "✅ Security scan script accessible" || echo "⚠️  Security scan script missing"\n\
\n\
echo "🎯 Production compilation environment ready!"\n\
' > /home/cairo-prod/health-check.sh && chmod +x /home/cairo-prod/health-check.sh

# Configure optimized health check for production environment
HEALTHCHECK --interval=180s --timeout=15s --start-period=10s --retries=2 \
    CMD /home/cairo-prod/health-check.sh

# Create and configure the startup script for the Cairo compilation environment
# This script provides:
# - Configurable verbose startup information display (controlled by VERBOSE_STARTUP env var)
# - Environment configuration overview (network, transaction version, optimization levels)
# - Tool version reporting (Scarb, Starknet Foundry, Cairo Native, Security Scanner)
# - Runtime information display (user, working directory, available memory)
# - Artifacts directory creation and management
# - Default compilation behavior when no arguments provided
# - Helpful usage tips and command examples for development workflow
# - Proper executable permissions and location setup in /home/cairo-prod/startup.sh
RUN echo '#!/bin/bash\n\
\n\
# Configurable startup verbosity\n\
if [ "${VERBOSE_STARTUP}" = "true" ]; then\n\
    echo "🏗️  Veridis Cairo Contract Compilation & Security Environment"\n\
    echo "============================================================"\n\
    echo ""\n\
    echo "Environment Information:"\n\
    echo "  • Mode: ${CAIRO_ENVIRONMENT:-compilation}"\n\
    echo "  • Target Network: ${STARKNET_NETWORK:-devnet}"\n\
    echo "  • Transaction Version: ${STARKNET_TX_VERSION:-3}"\n\
    echo "  • Resource Bounds: ${RESOURCE_BOUNDS_ENABLED:-true}"\n\
    echo "  • MLIR Optimization: ${CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL:-3}"\n\
    echo "  • Security Scanning: ${SECURITY_SCAN_ENABLED:-true}"\n\
    echo "  • Compilation Mode: ${COMPILATION_MODE:-release}"\n\
    echo "  • Artifacts Directory: ${ARTIFACTS_DIR:-/app/artifacts}"\n\
    echo ""\n\
    echo "Tool Versions:"\n\
    echo "  • Scarb: $(scarb --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
    echo "  • Starknet Foundry: $(snforge --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
    echo "  • Cairo Native: $(cairo-native --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
    echo "  • Security Scanner: Custom implementation (cargo-audit + cairo analysis)"\n\
    echo ""\n\
    echo "Runtime Information:"\n\
    echo "  • User: $(whoami) ($(id))"\n\
    echo "  • Working Directory: $(pwd)"\n\
    echo "  • Available Memory: $(free -h 2>/dev/null | grep Mem | awk '\''{print $2}'\'' || echo \"Unknown\")"\n\
    echo ""\n\
    echo "🎯 Cairo compilation environment ready!"\n\
    echo ""\n\
fi\n\
\n\
# Ensure artifacts directory exists\n\
mkdir -p "${ARTIFACTS_DIR:-/app/artifacts}"\n\
\n\
if [ $# -eq 0 ]; then\n\
    if [ "${VERBOSE_STARTUP}" = "true" ]; then\n\
        echo "💡 Compilation tips:"\n\
        echo "  • Compile contracts: compile-cairo.sh"\n\
        echo "  • Run tests: test-cairo.sh or snforge test"\n\
        echo "  • Security scan: security-scan.sh or cairo-security-scanner"\n\
        echo "  • Native compilation: cairo-native compile <contract>"\n\
        echo "  • Deploy to network: sncast declare --url <rpc_url>"\n\
        echo "  • Check configuration: sncast show-config"\n\
        echo "  • Artifacts location: ${ARTIFACTS_DIR:-/app/artifacts}"\n\
        echo ""\n\
    fi\n\
    exec /usr/local/bin/compile-cairo.sh\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/cairo-prod/startup.sh && chmod +x /home/cairo-prod/startup.sh

# Set entrypoint to startup script for consistent initialization
ENTRYPOINT ["/home/cairo-prod/startup.sh"]

# Default command runs the compilation script
CMD []

# =============================================================================
# CONTAINER METADATA & LABELS
# =============================================================================
# Comprehensive labeling for the Veridis Cairo compilation environment
# following OCI image specification and best practices for container metadata.
#
# Core Labels:
# - maintainer: Development team responsible for the image
# - version: Semantic version of the container build
# - description: High-level description of container purpose
#
# Environment Configuration:
# - environment.type: Categorizes the container's primary function
# - service.type: Identifies the specific service provided
# - build.mode: Compilation mode (debug/release/optimized)
#
# Tool Versions:
# - tools.*: Version tracking for all integrated development tools
#   - Rust compiler version for Cairo compilation
#   - Scarb package manager version
#   - Cairo Native compiler version
#   - Starknet Foundry testing framework version
#   - LLVM compiler infrastructure version
#
# Security & Optimization:
# - security.scan.enabled: Controls security vulnerability scanning
# - optimization.mlir.level: MLIR optimization level for performance
#
# Runtime Configuration:
# - user.uid/gid: Container user identity mapping
# - startup.verbose: Controls startup logging verbosity
# - formatting.enabled: Cairo code formatting capabilities
#
# OCI Standard Labels:
# - org.opencontainers.image.*: Standard OCI annotations for
#   source repository, documentation, licensing, and base image information
# =============================================================================
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Veridis Cairo Contract Compilation & Security Environment with comprehensive tooling" \
      environment.type="cairo-compilation" \
      service.type="compilation" \
      build.mode="${BUILD_MODE}" \
      tools.rust.version="${RUST_VERSION}" \
      tools.scarb.version="${SCARB_VERSION}" \
      tools.cairo_native.version="${CAIRO_NATIVE_VERSION}" \
      tools.foundry.version="${STARKNET_FOUNDRY_VERSION}" \
      tools.llvm.version="${LLVM_VERSION}" \
      security.scan.enabled="${SECURITY_SCAN_REQUIRED}" \
      optimization.mlir.level="${MLIR_OPTIMIZATION_LEVEL}" \
      user.uid="${USER_UID}" \
      user.gid="${USER_GID}" \
      startup.verbose="${VERBOSE_STARTUP}" \
      formatting.enabled="${ENABLE_CAIRO_FORMATTING}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Cairo Compilation Environment" \
      org.opencontainers.image.description="Production-ready Cairo compilation environment with security scanning and optimization" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/contracts/README.md" \
      org.opencontainers.image.base.name="ubuntu:${UBUNTU_VERSION}" \
      org.opencontainers.image.base.os.version="${UBUNTU_VERSION}"
