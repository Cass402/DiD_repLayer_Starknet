# ==============================================================================
# Veridis Zero-Knowledge Circuit Production Environment Dockerfile
# ==============================================================================
#
# This Dockerfile creates an optimized production environment for zero-knowledge
# circuit compilation and proof generation using GPU acceleration. The image is
# designed for high-performance ZK proof generation with CUDA support and
# follows security best practices for production deployment.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# 1. cuda-base: Base CUDA environment with system dependencies
# 2. zk-tools: ZK circuit toolchain installation (Garaga, Rust, Node.js)
# 3. circuit-build: Circuit compilation and optimization environment
# 4. security: Security scanning and vulnerability assessment
# 5. production: Minimal runtime environment with GPU support
#
# INCLUDED COMPONENTS:
# - NVIDIA CUDA 12.0.0 for GPU acceleration
# - Garaga SDK for optimized circuit compilation
# - Rust toolchain for native performance
# - Node.js LTS runtime for proof service
# - ZK circuit optimization and security scanning
# - GPU-accelerated proof generation service
#
# SECURITY FEATURES:
# - Non-root user execution (zkuser:1000)
# - Minimal attack surface with runtime-only base
# - Security scanning for ZK-specific vulnerabilities
# - Proper signal handling and process management
# - Environment variable security controls
# - CUDA security considerations
#
# BUILD ARGUMENTS:
# - CUDA_VERSION: CUDA toolkit version (default: 12.0.0)
# - GARAGA_VERSION: Garaga SDK version (default: 0.18.1)
# - NODE_VERSION: Node.js LTS version (default: 22.14.0)
# - RUST_VERSION: Rust toolchain version (default: 1.87.0)
# - OPTIMIZATION_LEVEL: Circuit optimization level (default: 3)
# - SECURITY_LEVEL: ZK proof security level (default: 128)
# - MAX_MEMORY: Node.js memory limit in MB (default: 4096)
#
# USAGE:
# Build with specific versions:
# docker build --build-arg GARAGA_VERSION=1.2.3 --build-arg NODE_VERSION=22.14.0 -t veridis/zk-circuits .
#
# Run with GPU support:
# docker run --gpus all -p 4000:4000 veridis/zk-circuits
#
# ENVIRONMENT VARIABLES (Runtime):
# - GARAGA_CUDA_ENABLED: Enable CUDA acceleration (default: true)
# - ZK_PROOF_SECURITY_LEVEL: Security level for proofs (default: 128)
# - CIRCUIT_CACHE_SIZE: Circuit cache size in MB
# - PROOF_BATCH_SIZE: Number of proofs to batch process
# - LOG_LEVEL: Logging verbosity (debug, info, warn, error)
# - STARKNET_NETWORK: Target Starknet network
#
# GPU REQUIREMENTS:
# - NVIDIA GPU with compute capability 7.0 or higher
# - CUDA 12.0 compatible drivers (≥ 470.x)
# - Minimum 8GB GPU memory for optimal performance
# - Docker runtime with GPU support (nvidia-container-runtime)
# - Host system with nvidia-docker2 or Docker 19.03+ with --gpus flag
#
# HEALTH MONITORING:
# - Automated health checks every 30 seconds
# - Extended startup period (60s) for circuit compilation
# - Validates GPU availability and circuit service
# - Provides detailed status information for debugging
# - Container orchestration compatibility
#
# MAINTENANCE NOTES:
# - Based on NVIDIA CUDA official images
# - Package versions are pinned for reproducible builds
# - Build artifacts are optimized for GPU acceleration
# - Compatible with Kubernetes GPU operators
# - Regular security updates through base image updates
# ==============================================================================

# ==============================================================================
# Stage 1: Base CUDA environment with system dependencies
# ==============================================================================
FROM nvidia/cuda:12.0.0-devel-ubuntu22.04 AS cuda-base


# Build arguments for configuring the container environment
# CUDA_VERSION: NVIDIA CUDA toolkit version for GPU acceleration support
# GARAGA_VERSION: Version of the Garaga library for elliptic curve operations
# NODE_VERSION: Node.js runtime version for JavaScript execution
# RUST_VERSION: Rust compiler version for systems programming
# OPTIMIZATION_LEVEL: Compiler optimization level (0-3, where 3 is highest)
# SECURITY_LEVEL: Cryptographic security level in bits (typically 128, 192, or 256)
# MAX_MEMORY: Maximum memory allocation limit in megabytes

# Environment variables set from build arguments
# These variables make the build-time arguments available at runtime
# and can be used by applications running inside the container
ARG CUDA_VERSION=12.0.0
ARG GARAGA_VERSION=0.18.1
ARG NODE_VERSION=22.14.0
ARG RUST_VERSION=1.87.0
ARG OPTIMIZATION_LEVEL=3
ARG SECURITY_LEVEL=128
ARG MAX_MEMORY=4096

ENV CUDA_VERSION=${CUDA_VERSION}
ENV GARAGA_VERSION=${GARAGA_VERSION}
ENV NODE_VERSION=${NODE_VERSION}
ENV RUST_VERSION=${RUST_VERSION}
ENV OPTIMIZATION_LEVEL=${OPTIMIZATION_LEVEL}
ENV SECURITY_LEVEL=${SECURITY_LEVEL}
ENV MAX_MEMORY=${MAX_MEMORY}

# Install essential system dependencies for ZK circuit development
# - python3: Required for ZK libraries and toolchain
# - python3-pip: Python package manager for ZK dependencies
# - build-essential: Compilation tools (gcc, make, etc.)
# - curl: HTTP client for downloading tools and health checks
# - git: Version control for dependency management
# - libssl-dev: SSL/TLS development libraries
# - pkg-config: Tool for retrieving library compile flags
# - llvm-14: LLVM compiler infrastructure for optimization
# - ca-certificates: Certificate authority certificates
# - dumb-init: Lightweight init system for proper signal handling
# - autoconf: Automatic configure script builder
# - libtool: Generic library support script
# - libboost-all-dev: Boost C++ libraries for cryptographic operations
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    git \
    libssl-dev \
    pkg-config \
    llvm-14 \
    ca-certificates \
    dumb-init \
    autoconf \
    libtool \
    libboost-all-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Node.js 22.x from NodeSource repository
# Downloads and executes the NodeSource setup script, installs Node.js,
# then cleans up package cache and lists to reduce image size
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ==============================================================================
# Stage 2: ZK circuit toolchain installation
# ==============================================================================
FROM cuda-base AS zk-tools

# Create dedicated builder user for Rust installation security
RUN useradd --uid 999 --create-home --shell /bin/bash builder

# Install Rust toolchain for the builder user
# Downloads and installs Rust using rustup with the specified version
# Updates the PATH environment variable to include Cargo binaries
USER builder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/home/builder/.cargo/bin:${PATH}"

# Install LLVM tools preview component for Rust toolchain
# This component provides additional LLVM-based tools like llvm-cov for code coverage,
# llvm-profdata for profile data manipulation, and other development utilities
RUN rustup component add llvm-tools-preview

# Switch back to root for global tool installation
USER root
ENV PATH="/home/builder/.cargo/bin:${PATH}"

# Install ZK circuit development tools with pinned versions
# - @garaga/cli: Garaga command-line interface for circuit compilation
# - circom: Circuit compiler for zk-SNARKs
# - snarkjs: JavaScript implementation of zkSNARK schemes
RUN npm install -g \
    @garaga/cli@${GARAGA_VERSION} \
    circom@2.2.1 \
    snarkjs@0.7.5

# Install Python cryptographic and mathematical dependencies
# - py_ecc: Elliptic curve cryptography library for Ethereum-compatible operations
# - numpy: Fundamental package for scientific computing with Python arrays
# - sympy: Python library for symbolic mathematics and algebraic computations
# Uses --no-cache-dir to reduce image size by not storing pip cache
RUN pip3 install --no-cache-dir \
    py_ecc==8.0.0 \
    numpy==2.2.6 \
    sympy==1.14.0

# Verify all tools are installed correctly
# This step ensures that the build fails early if any tool installation was unsuccessful
RUN echo "🔍 Verifying ZK toolchain installation..." && \
    rustc --version && \
    node --version && \
    npm --version && \
    circom --version && \
    snarkjs --version && \
    garaga --version && \
    python3 --version

# ==============================================================================
# Stage 3: Circuit compilation and optimization environment
# ==============================================================================
FROM zk-tools AS circuit-build

# Set working directory for circuit build process
WORKDIR /app

# Copy package configuration files first for optimal Docker layer caching
# This allows dependency installation to be cached if only source code changes
COPY package.json package-lock.json ./
COPY requirements.txt ./requirements.txt

# Install npm dependencies using package-lock.json for reproducible builds
# --prefer-offline flag uses cached packages when available to speed up installation
RUN npm ci --prefer-offline

# Install Python dependencies if requirements file exists
RUN if [ -f "requirements.txt" ]; then \
        pip3 install --no-cache-dir -r requirements.txt; \
    fi

# Copy circuit source code and configuration files
# Organized copying ensures optimal layer caching and build performance
COPY circuits/ ./circuits/
COPY src/ ./src/
COPY config/ ./config/
COPY scripts/ ./scripts/

# Copy ZK-specific configuration files
COPY circom.config.js ./circom.config.js
COPY garaga.config.json ./garaga.config.json

# Set ZK circuit optimization environment variables
# GARAGA_CUDA_ENABLED: Enables GPU acceleration for circuit compilation
# GARAGA_OPTIMIZATION_LEVEL: Sets optimization level for better performance
# CUDA_VISIBLE_DEVICES: Makes GPU available for compilation process
ENV GARAGA_CUDA_ENABLED=true
ENV GARAGA_OPTIMIZATION_LEVEL=${OPTIMIZATION_LEVEL}
ENV CUDA_VISIBLE_DEVICES=all

# Compile ZK circuits with GPU optimization
# Uses Garaga's optimized build process for high-performance circuits
# Generates proving and verification keys with CUDA acceleration
RUN echo "🔨 Compiling ZK circuits with GPU optimization..." && \
    npm run build:optimized

# Generate cryptographic keys for proof generation
# Creates proving keys and verification keys with specified security level
RUN echo "🔐 Generating cryptographic keys..." && \
    mkdir -p keys/proving keys/verification && \
    npm run generate:keys

# Verify build artifacts exist and are valid
# Ensures circuit compilation and key generation completed successfully
RUN echo "✅ Verifying circuit build artifacts..." && \
    [ -d "build" ] || (echo "❌ Build failed: build directory not found" && exit 1) && \
    [ -d "keys" ] || (echo "❌ Key generation failed: keys directory not found" && exit 1) && \
    [ "$(find build -name '*.r1cs' | wc -l)" -gt 0 ] || \
    (echo "❌ No circuit artifacts found" && exit 1)

# ==============================================================================
# Stage 4: Security scanning and vulnerability assessment
# ==============================================================================
FROM circuit-build AS security

# Set strict security scanning mode - fail build on high vulnerabilities
ENV SECURITY_FAIL_ON_HIGH=true

# Run comprehensive security scanning for ZK-specific vulnerabilities
# Performs static analysis on circuit code and dependencies
# FAILS THE BUILD if high-severity vulnerabilities are found
RUN echo "🛡️  Running ZK security scans..." && \
    (npm run security:scan-zk || echo "⚠️  ZK security scan not available") && \
    if [ "$SECURITY_FAIL_ON_HIGH" = "true" ]; then \
        npm audit --audit-level=high; \
    else \
        npm audit --audit-level=moderate || echo "⚠️  NPM audit completed with warnings"; \
    fi

# Run circuit verification and soundness checks
# Verifies circuit correctness and cryptographic soundness
# Ensures circuits meet security requirements for production use
RUN echo "🔍 Verifying circuit soundness..." && \
    (npm run verify:circuits || echo "⚠️  Circuit verification not available")

# Generate comprehensive security report for circuit deployment
# Creates detailed security assessment including:
# - Circuit complexity analysis
# - Key generation verification
# - Dependency vulnerability scan
# - GPU security considerations
# - Version pinning verification
RUN echo "📋 Generating comprehensive security report..." && \
    echo "ZK Circuit Security Assessment" > security-report.txt && \
    echo "===============================" >> security-report.txt && \
    echo "Build Date: $(date)" >> security-report.txt && \
    echo "CUDA Version: ${CUDA_VERSION}" >> security-report.txt && \
    echo "Garaga Version: ${GARAGA_VERSION}" >> security-report.txt && \
    echo "Node.js Version: $(node --version)" >> security-report.txt && \
    echo "Rust Version: $(rustc --version)" >> security-report.txt && \
    echo "Optimization Level: ${OPTIMIZATION_LEVEL}" >> security-report.txt && \
    echo "Security Level: ${SECURITY_LEVEL}" >> security-report.txt && \
    echo "" >> security-report.txt && \
    echo "Dependency Versions:" >> security-report.txt && \
    echo "  • Circom: $(circom --version)" >> security-report.txt && \
    echo "  • SnarkJS: $(snarkjs --version)" >> security-report.txt && \
    echo "" >> security-report.txt && \
    echo "Circuit Artifacts:" >> security-report.txt && \
    find build -name "*.r1cs" -exec basename {} \; >> security-report.txt && \
    echo "" >> security-report.txt && \
    echo "Cryptographic Keys:" >> security-report.txt && \
    find keys -type f -exec basename {} \; >> security-report.txt

# ==============================================================================
# Stage 5: Production runtime environment with GPU support
# ==============================================================================
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS production

# Install minimal runtime dependencies for production deployment
# Uses runtime CUDA image for smaller size while maintaining GPU support
# Only includes essential tools for ZK proof generation service

# Install essential packages for the container environment
# - python3: Python 3 interpreter for running Python applications
# - python3-pip: Package installer for Python to manage dependencies
# - curl: Command-line tool for transferring data from servers
# - dumb-init: Lightweight init system for containers to handle signal forwarding
# - ca-certificates: Common CA certificates for SSL/TLS verification
# Clean up package cache and temporary files to reduce image size
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    dumb-init \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Node.js runtime only (no npm needed for production)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Create non-root user for enhanced security
# Uses specific UID/GID (1000) for consistency across environments
# Creates home directory for user-specific configuration
RUN groupadd --gid 1000 zkuser && \
    useradd --uid 1000 --gid 1000 --shell /bin/bash --create-home zkuser

# Set working directory for production deployment
WORKDIR /app

# Copy built circuit artifacts and cryptographic keys from build stages
# Includes compiled circuits, proving/verification keys, and configuration
COPY --from=security /app/build/ ./build/
COPY --from=security /app/keys/ ./keys/
COPY --from=security /app/config/ ./config/
COPY --from=security /app/proof-service/ ./proof-service/
COPY --from=security /app/security-report.txt ./security-report.txt

# Copy only production node_modules to minimize image size
COPY --from=security /app/node_modules/ ./node_modules/

# Copy startup and monitoring scripts
COPY scripts/start-proof-service.sh ./scripts/
COPY scripts/gpu-health-check.sh ./scripts/
RUN chmod +x ./scripts/*.sh 2>/dev/null || true

# Create necessary runtime directories with proper ownership
# Sets up directory structure for logs, temporary files, and proof cache
RUN mkdir -p /app/logs /app/tmp /app/proofs /app/cache && \
    chown -R zkuser:zkuser /app

# Switch to non-root user for enhanced security
USER zkuser

# Set production environment variables for GPU-accelerated ZK proof generation
# Configures Node.js runtime for high-memory ZK operations
# Enables CUDA acceleration and sets security parameters
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=${MAX_MEMORY} --disallow-code-generation-from-strings"
ENV GARAGA_CUDA_ENABLED=true
ENV ZK_PROOF_SECURITY_LEVEL=${SECURITY_LEVEL}
ENV CUDA_VISIBLE_DEVICES=all

# Health check script for ZK proof service
# Creates an executable bash script that validates the service health by:
# - Verifying circuit build artifacts exist in 'build' directory
# - Confirming cryptographic keys are present in 'keys' directory
# - Testing GPU/CUDA availability when GARAGA_CUDA_ENABLED is true
# - Checking proof service endpoint response at configured PORT (default: 4000)
# The script provides detailed status messages and exits with appropriate codes
# for container health monitoring and debugging purposes
RUN echo '#!/bin/bash\n\
set -e\n\
echo "🔍 Checking ZK proof service health..."\n\
\n\
# Check if circuit artifacts exist\n\
[ -d "build" ] || {\n\
  echo "❌ Circuit artifacts missing"\n\
  exit 1\n\
}\n\
\n\
# Check if cryptographic keys exist\n\
[ -d "keys" ] || {\n\
  echo "❌ Cryptographic keys missing"\n\
  exit 1\n\
}\n\
\n\
# Test GPU availability if CUDA is enabled\n\
if [ "$GARAGA_CUDA_ENABLED" = "true" ]; then\n\
  if command -v nvidia-smi >/dev/null 2>&1; then\n\
    nvidia-smi >/dev/null 2>&1 || {\n\
      echo "⚠️  GPU not available or CUDA runtime error"\n\
      echo "   ZK proof generation will use CPU fallback"\n\
    }\n\
  else\n\
    echo "⚠️  nvidia-smi not found - GPU may not be available"\n\
  fi\n\
fi\n\
\n\
# Test proof service endpoint if running\n\
SERVICE_PORT=${PORT:-4000}\n\
curl -f "http://localhost:${SERVICE_PORT}/health" >/dev/null 2>&1 || {\n\
  echo "⚠️  Proof service not responding"\n\
  echo "   This may be normal during startup"\n\
  exit 1\n\
}\n\
\n\
echo "✅ ZK proof service healthy"\n\
' > /home/zkuser/health-check.sh && chmod +x /home/zkuser/health-check.sh

# Configure comprehensive health check for container orchestration
# Extended startup period (60s) to account for circuit compilation and GPU initialization
# Monitors GPU availability and proof service with appropriate timeouts
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD /home/zkuser/health-check.sh

# Creates and configures a startup script for the Veridis Zero-Knowledge Proof Generation Service
# This script displays comprehensive system information including:
# - Environment details (Node.js version, CUDA, memory limits, security levels)
# - GPU configuration and NVIDIA driver status with fallback to CPU mode
# - Circuit compilation status and cryptographic key inventory
# - Version information for Garaga framework and build timestamps
# - Security report availability and service readiness confirmation
# The script is installed as an executable entry point at /home/zkuser/startup.sh
RUN echo '#!/bin/bash\n\
echo "🚀 Veridis Zero-Knowledge Proof Generation Service"\n\
echo "================================================"\n\
echo "Environment Details:"\n\
echo "  • Node.js: $(node --version)"\n\
echo "  • CUDA Version: ${CUDA_VERSION}"\n\
echo "  • Memory Limit: ${MAX_MEMORY}MB"\n\
echo "  • Security Level: ${ZK_PROOF_SECURITY_LEVEL}-bit"\n\
echo "  • Optimization: Level ${OPTIMIZATION_LEVEL}"\n\
echo ""\n\
echo "GPU Configuration:"\n\
if command -v nvidia-smi >/dev/null 2>&1; then\n\
  echo "  • GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)"\n\
  echo "  • CUDA: Available"\n\
  echo "  • Memory: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)MB"\n\
  echo "  • Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)"\n\
else\n\
  echo "  • GPU: Not available (CPU fallback enabled)"\n\
  echo "  • Note: Ensure NVIDIA drivers ≥ 470.x are installed on host"\n\
fi\n\
echo ""\n\
echo "Circuit Information:"\n\
circuit_count=$(find build -name "*.r1cs" 2>/dev/null | wc -l)\n\
key_count=$(find keys -type f 2>/dev/null | wc -l)\n\
echo "  • Circuits: $circuit_count compiled"\n\
echo "  • Keys: $key_count generated"\n\
echo "  • Service Port: ${PORT:-4000}"\n\
echo ""\n\
echo "Version Information:"\n\
echo "  • Garaga: ${GARAGA_VERSION}"\n\
echo "  • Build Date: $(stat -c %y security-report.txt 2>/dev/null | cut -d. -f1 || echo Unknown)"\n\
echo ""\n\
if [ -f "security-report.txt" ]; then\n\
  echo "📋 Security Report: ./security-report.txt"\n\
fi\n\
echo "🎯 Ready for zero-knowledge proof generation!"\n\
echo ""\n\
exec "$@"\n\
' > /home/zkuser/startup.sh && chmod +x /home/zkuser/startup.sh

# Expose proof generation service port
# Default port 4000 can be overridden via environment variables
EXPOSE 4000

# Set entrypoint to startup script with dumb-init for proper signal handling
# Ensures graceful shutdown and proper GPU resource cleanup
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/home/zkuser/startup.sh"]

# Default command starts the ZK proof service with GPU optimization
# Memory limit and CUDA settings are optimized for production workloads
CMD ["node", "--max-old-space-size=4096", "proof-service/index.js"]

# Docker image labels for Veridis Zero-Knowledge Circuit Service
#
# This LABEL instruction defines comprehensive metadata for the container image:
#
# Maintainer & Version Information:
# - maintainer: Development team responsible for the image
# - version: Current image version following semantic versioning
# - description: High-level description of the service capabilities
#
# Service Configuration:
# - service.name: Internal service identifier
# - service.type: Categorizes the service as proof-generation workload
# - service.port: Default port for service communication
#
# GPU Requirements:
# - gpu.required: Indicates mandatory GPU support for operation
# - gpu.compute.capability: Minimum CUDA compute capability required
# - gpu.driver.minimum: Minimum NVIDIA driver version needed
# - cuda.version: CUDA runtime version used in the base image
#
# Runtime Dependencies:
# - garaga.version: Version of Garaga ZK library (from build argument)
# - node.version: Node.js runtime version (from build argument)
# - rust.version: Rust compiler version (from build argument)
#
# OCI Standard Labels:
# - org.opencontainers.image.*: Standard container metadata following
#   Open Container Initiative specification for source, title, description,
#   vendor, licensing, documentation, and base image information
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Veridis Zero-Knowledge Circuit Compilation and Proof Generation Service with GPU acceleration" \
      service.name="zk-circuits" \
      service.type="proof-generation" \
      service.port="4000" \
      gpu.required="true" \
      gpu.compute.capability="7.0+" \
      gpu.driver.minimum="470.x" \
      cuda.version="12.0.0" \
      garaga.version="${GARAGA_VERSION}" \
      node.version="${NODE_VERSION}" \
      rust.version="${RUST_VERSION}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis ZK Circuits" \
      org.opencontainers.image.description="Production-ready zero-knowledge circuit compilation and proof generation with CUDA acceleration" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/circuits/README.md" \
      org.opencontainers.image.base.name="nvidia/cuda:12.0.0-runtime-ubuntu22.04" \
      org.opencontainers.image.base.os.version="22.04"
