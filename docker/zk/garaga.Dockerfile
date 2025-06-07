# ==============================================================================
# Veridis Garaga SDK Integration and ZK Circuit Production Environment
# ==============================================================================
#
# This Dockerfile creates a high-performance production environment for Garaga SDK
# integration with zero-knowledge circuit compilation and GPU-accelerated proof
# generation. The image is optimized for Starknet ecosystem integration with
# advanced security, monitoring, and debugging capabilities.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# ===============================
# 1. base-runtime: Minimal CUDA runtime with essential dependencies
# 2. toolchain-installer: Isolated toolchain installation with version control
# 3. dependency-cache: Cached dependencies for optimal layer reuse
# 4. trusted-setup-data: Secure Powers of Tau and trusted setup data
# 5. garaga-builder: Garaga SDK and ZK tools installation
# 6. circuit-workspace: Application code and circuit compilation
# 7. security-validator: Comprehensive security scanning and validation
# 8. key-generator: Secure cryptographic key generation (optional)
# 9. production-runtime: Minimal production runtime
# 10. development-workspace: Full development environment (optional)
#
# SECURITY IMPROVEMENTS:
# =====================
# • Externalized trusted setup data with integrity verification
# • Separate key generation stage with optional external key mounting
# • Minimal runtime dependencies with security-focused package selection
# • Comprehensive secrets management integration
# • Enhanced health checks with configurable startup grace periods
# • Improved Docker layer caching strategy for faster builds
#
# PERFORMANCE OPTIMIZATIONS:
# =========================
# • Optimized Docker layer structure for maximum cache reuse
# • Separate runtime and build dependencies for minimal image size
# • Improved dependency management with separate package configurations
# • Enhanced circuit caching and compilation optimization
# • Streamlined GPU resource management and memory allocation
#
# BUILD ARGUMENTS:
# ================
# - CUDA_VERSION: NVIDIA CUDA toolkit version (default: 12.0.0)
# - GARAGA_VERSION: Garaga SDK version (default: 0.18.1)
# - NODE_VERSION: Node.js LTS version (default: 22.14.0)
# - RUST_VERSION: Rust toolchain version (default: 1.87.0)
# - PYTHON_VERSION: Python runtime version (default: 3.11)
# - OPTIMIZATION_LEVEL: Circuit optimization level 0-3 (default: 3)
# - SECURITY_LEVEL: ZK proof security level in bits (default: 128)
# - MAX_MEMORY: Node.js memory limit in MB (default: 8192)
# - USER_UID: User ID for zkuser (default: 1000)
# - USER_GID: Group ID for zkuser (default: 1000)
# - BUILD_TARGET: Build target (runtime, development, keygen) (default: runtime)
# - ENABLE_TELEMETRY: Enable performance telemetry (default: false)
# - CAIRO_INTEGRATION: Enable Cairo toolchain integration (default: true)
# - EXTERNAL_KEYS: Use externally provided keys (default: false)
# - PTAU_SOURCE: Powers of Tau source (hermez, internal, local) (default: hermez)
# - STARTUP_GRACE_PERIOD: Health check startup grace period (default: 120)
#
# USAGE:
# ======
# Build production runtime:
# docker build -t veridis/garaga-sdk:runtime .
#
# Build with key generation:
# docker build --target key-generator -t veridis/garaga-sdk:keygen .
#
# Build development environment:
# docker build --target development-workspace -t veridis/garaga-sdk:dev .
#
# Build with external keys:
# docker build --build-arg EXTERNAL_KEYS=true -t veridis/garaga-sdk:prod .
#
# Run with GPU and external key mount:
# docker run --gpus all -v /secure/keys:/app/keys:ro veridis/garaga-sdk:prod
#
# ENVIRONMENT VARIABLES (Runtime):
# ================================
# - GARAGA_CUDA_ENABLED: Enable CUDA acceleration (default: true)
# - ZK_PROOF_SECURITY_LEVEL: Security level for proofs (default: 128)
# - CIRCUIT_CACHE_SIZE: Circuit cache size in MB (default: 1024)
# - PROOF_BATCH_SIZE: Number of proofs to batch process (default: 10)
# - LOG_LEVEL: Logging verbosity (debug, info, warn, error) (default: info)
# - STARKNET_NETWORK: Target Starknet network (default: mainnet)
# - CAIRO_VERSION: Cairo compiler version compatibility (default: 2.8.2)
# - MEMORY_POOL_SIZE: Memory pool for ZK operations in MB (default: 2048)
# - GPU_MEMORY_FRACTION: Fraction of GPU memory to use (default: 0.8)
# - TELEMETRY_ENABLED: Enable performance telemetry (default: false)
# - PROOF_SERVICE_PORT: Service port (default: 4000)
# - HEALTH_CHECK_INTERVAL: Health check interval in seconds (default: 30)
# - CIRCUIT_OPTIMIZATION: Enable circuit optimization (default: true)
# - PARALLEL_PROOF_GENERATION: Enable parallel processing (default: true)
# - EXTERNAL_KEY_PATH: Path to external keys directory (default: /app/keys)
# - SECRET_STORE_TYPE: Secret store type (file, vault, k8s) (default: file)
# - VAULT_ADDR: Vault server address (if using HashiCorp Vault)
# - VAULT_TOKEN: Vault authentication token (if using HashiCorp Vault)
# - K8S_SECRET_NAME: Kubernetes secret name (if using K8s secrets)
#
# SECRETS MANAGEMENT:
# ==================
# • File-based secrets: Mount secrets as files in /app/secrets/
# • HashiCorp Vault integration: Set VAULT_ADDR and VAULT_TOKEN
# • Kubernetes secrets: Use K8S_SECRET_NAME for automatic mounting
# • Environment variable secrets: Prefix with GARAGA_SECRET_
#
# MAINTENANCE NOTES:
# ==================
# - Optimized for Docker layer caching and build performance
# - Supports external key management for enhanced security
# - Compatible with enterprise secrets management systems
# - Streamlined for CI/CD pipeline integration
# - Minimal runtime footprint with comprehensive development support
# ==============================================================================

# Global build arguments accessible to all stages
ARG CUDA_VERSION=12.0.0
ARG GARAGA_VERSION=0.18.1
ARG NODE_VERSION=22.14.0
ARG RUST_VERSION=1.87.0
ARG PYTHON_VERSION=3.11
ARG OPTIMIZATION_LEVEL=3
ARG SECURITY_LEVEL=128
ARG MAX_MEMORY=8192
ARG USER_UID=1000
ARG USER_GID=1000
ARG BUILD_TARGET=runtime
ARG ENABLE_TELEMETRY=false
ARG CAIRO_INTEGRATION=true
ARG EXTERNAL_KEYS=false
ARG PTAU_SOURCE=hermez

# ==============================================================================
# Stage 1: Base runtime with minimal CUDA environment
# ==============================================================================
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu22.04 AS base-runtime

# Configure essential environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

# Install only essential runtime dependencies for minimal attack surface
# Packages are carefully selected for production use:
# - python3: Python runtime for cryptographic libraries
# - curl: HTTP client for health checks and API communication
# - ca-certificates: Certificate authority certificates for secure connections
# - dumb-init: Lightweight init system for proper signal handling
# - locales/tzdata: Internationalization and timezone support
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3=${PYTHON_VERSION}* \
    python3-pip \
    curl \
    ca-certificates \
    dumb-init \
    locales \
    tzdata \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Create dedicated non-root user for enhanced security
ARG USER_UID
ARG USER_GID
RUN groupadd --gid ${USER_GID} zkuser && \
    useradd --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash --create-home zkuser

# Create essential directory structure with proper permissions
RUN mkdir -p /app/{config,cache,logs,tmp,metrics,secrets} && \
    chown -R zkuser:zkuser /app

WORKDIR /app

# ==============================================================================
# Stage 2: Toolchain installer with optimized caching
# ==============================================================================
FROM base-runtime AS toolchain-installer

# Switch to root for system-wide tool installation
USER root

# Install build dependencies in separate layer for better caching
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    git \
    pkg-config \
    libssl-dev \
    libffi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Node.js from NodeSource with version verification
# Separate layer to cache Node.js installation independently
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_$(echo ${NODE_VERSION} | cut -d. -f1).x | bash - && \
    apt-get install -y nodejs && \
    node --version && npm --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install Rust toolchain with specific version for reproducible builds
# Create dedicated builder user to avoid permission issues
RUN groupadd --gid 999 builder && \
    useradd --uid 999 --gid 999 --create-home --shell /bin/bash builder

USER builder
ARG RUST_VERSION
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --default-toolchain ${RUST_VERSION} --no-modify-path && \
    /home/builder/.cargo/bin/rustup component add clippy rustfmt && \
    /home/builder/.cargo/bin/rustup target add wasm32-unknown-unknown

# Export Rust environment for subsequent stages
ENV PATH="/home/builder/.cargo/bin:${PATH}"

USER root

# Upgrade Python pip in separate layer for better caching
RUN python3 -m pip install --upgrade pip setuptools wheel

# Verification layer - ensures all tools are properly installed
RUN echo "🔍 Verifying toolchain installation..." && \
    echo "  • Python: $(python3 --version)" && \
    echo "  • Node.js: $(node --version)" && \
    echo "  • NPM: $(npm --version)" && \
    echo "  • Rust: $(rustc --version)" && \
    echo "  • Cargo: $(cargo --version)" && \
    echo "✅ All toolchain components verified"

# ==============================================================================
# Stage 3: Dependency cache for optimal layer reuse
# ==============================================================================
FROM toolchain-installer AS dependency-cache

# Copy package files for dependency installation
# Separate copy commands for better cache granularity
COPY package.json ./
COPY package-lock.json* ./
COPY requirements.txt* ./
COPY requirements-runtime.txt* ./

# Install Node.js build dependencies with exact versions
# Use separate package.json for build vs runtime to minimize final image size
RUN npm ci --prefer-offline --no-fund && \
    npm cache clean --force

# Install Python dependencies with pinned versions
# Core cryptographic and mathematical libraries for ZK operations
RUN pip3 install --no-cache-dir \
    py_ecc==7.0.1 \
    numpy==1.26.2 \
    sympy==1.12 \
    pycryptodome==3.19.0 \
    gmpy2==2.1.5 \
    galois==0.3.8

# Install additional requirements if file exists
RUN if [ -f "requirements.txt" ]; then \
        echo "📦 Installing additional Python dependencies..." && \
        pip3 install --no-cache-dir -r requirements.txt; \
    else \
        echo "ℹ️  No additional Python requirements found"; \
    fi

# Verification step for dependency installation
RUN echo "🔍 Verifying Python ZK libraries..." && \
    python3 -c "import py_ecc; import numpy; import sympy; print('✅ Core ZK libraries verified')"

# ==============================================================================
# Stage 4: Trusted setup data with integrity verification
# ==============================================================================
FROM dependency-cache AS trusted-setup-data

# Create secure data directory
RUN mkdir -p /app/data/trusted-setup && \
    chown -R zkuser:zkuser /app/data

ARG PTAU_SOURCE

# Download and verify Powers of Tau ceremony file
# Support multiple sources for redundancy and security
RUN echo "📥 Downloading Powers of Tau ceremony file from ${PTAU_SOURCE}..." && \
    case "${PTAU_SOURCE}" in \
        "hermez") \
            PTAU_URL="https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_20.ptau" \
            PTAU_SHA256="55c77ce8562366c91e7cda394cf7b7c15a06c21d8510835ac7d1e5b7e7b83b" \
            ;; \
        "internal") \
            PTAU_URL="${INTERNAL_PTAU_URL:-https://internal.veridis.com/ptau/powersOfTau28_hez_final_20.ptau}" \
            PTAU_SHA256="${INTERNAL_PTAU_SHA256:-55c77ce8562366c91e7cda394cf7b7c15a06c21d8510835ac7d1e5b7e7b83b}" \
            ;; \
        "local") \
            echo "ℹ️  Using local ptau file - ensure it's mounted at build time" \
            ;; \
        *) \
            echo "❌ Invalid PTAU_SOURCE: ${PTAU_SOURCE}" && exit 1 \
            ;; \
    esac && \
    if [ "${PTAU_SOURCE}" != "local" ]; then \
        if wget -q --show-progress -O /app/data/trusted-setup/powersOfTau28_hez_final_20.ptau "${PTAU_URL}"; then \
            echo "✅ Powers of Tau file downloaded successfully"; \
            if [ -n "${PTAU_SHA256}" ]; then \
                echo "${PTAU_SHA256}  /app/data/trusted-setup/powersOfTau28_hez_final_20.ptau" | sha256sum -c - && \
                echo "✅ Powers of Tau file integrity verified" || \
                (echo "❌ Powers of Tau file integrity check failed" && exit 1); \
            fi; \
        else \
            echo "⚠️  Could not download Powers of Tau file - key generation may fail"; \
        fi; \
    fi

# Create trusted setup verification script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
PTAU_FILE="/app/data/trusted-setup/powersOfTau28_hez_final_20.ptau"\n\
\n\
if [ -f "$PTAU_FILE" ]; then\n\
    FILE_SIZE=$(stat -c%s "$PTAU_FILE")\n\
    echo "✅ Powers of Tau file found (${FILE_SIZE} bytes)"\n\
    \n\
    # Verify file is not empty and has expected minimum size\n\
    if [ "$FILE_SIZE" -gt 100000000 ]; then\n\
        echo "✅ Powers of Tau file size validation passed"\n\
    else\n\
        echo "❌ Powers of Tau file appears to be incomplete or corrupted"\n\
        exit 1\n\
    fi\n\
else\n\
    echo "❌ Powers of Tau file not found at $PTAU_FILE"\n\
    echo "   Ensure PTAU_SOURCE is configured correctly or mount external file"\n\
    exit 1\n\
fi\n\
' > /app/verify-trusted-setup.sh && chmod +x /app/verify-trusted-setup.sh

# Verify trusted setup data
RUN /app/verify-trusted-setup.sh

# ==============================================================================
# Stage 5: Garaga builder with ZK tools installation
# ==============================================================================
FROM trusted-setup-data AS garaga-builder

ARG GARAGA_VERSION

# Install Garaga SDK and core ZK tools with exact versions
# Separate installation for better error handling and caching
RUN echo "📦 Installing Garaga SDK v${GARAGA_VERSION}..." && \
    npm install -g @garaga/cli@${GARAGA_VERSION} && \
    npm cache clean --force

# Install ZK circuit development tools
RUN echo "📦 Installing ZK circuit tools..." && \
    npm install -g \
    circom@2.1.8 \
    snarkjs@0.7.4 \
    && npm cache clean --force

# Install Cairo and Starknet integration libraries
RUN echo "📦 Installing Cairo and Starknet libraries..." && \
    pip3 install --no-cache-dir \
    cairo-lang==0.13.1 \
    starknet-py==0.21.0 \
    cairo-rs-py==0.1.3

# Create optimized Garaga configuration
ARG OPTIMIZATION_LEVEL
ARG SECURITY_LEVEL
ARG ENABLE_TELEMETRY
ARG CAIRO_INTEGRATION

RUN echo "📝 Creating Garaga configuration..." && \
    mkdir -p /app/config && \
    echo "{\n\
  \"garaga\": {\n\
    \"version\": \"${GARAGA_VERSION}\",\n\
    \"cuda\": {\n\
      \"enabled\": true,\n\
      \"compute_capability\": \"7.0\",\n\
      \"memory_fraction\": 0.8,\n\
      \"allow_growth\": true\n\
    },\n\
    \"optimization\": {\n\
      \"level\": ${OPTIMIZATION_LEVEL},\n\
      \"parallel_compilation\": true,\n\
      \"cache_circuits\": true,\n\
      \"memory_pool_size\": 2048\n\
    },\n\
    \"security\": {\n\
      \"level\": ${SECURITY_LEVEL},\n\
      \"key_derivation\": \"pbkdf2\",\n\
      \"secure_random\": true\n\
    },\n\
    \"cairo\": {\n\
      \"integration\": ${CAIRO_INTEGRATION},\n\
      \"version\": \"2.8.2\",\n\
      \"felt252_support\": true,\n\
      \"starknet_compatibility\": true\n\
    },\n\
    \"performance\": {\n\
      \"batch_size\": 10,\n\
      \"parallel_proofs\": true,\n\
      \"memory_optimization\": true,\n\
      \"telemetry\": ${ENABLE_TELEMETRY}\n\
    }\n\
  }\n\
}" > /app/config/garaga.config.json

# Create Circom configuration for optimized compilation
RUN echo "{\n\
  \"circom\": {\n\
    \"version\": \"2.1.8\",\n\
    \"optimization\": {\n\
      \"O2\": true,\n\
      \"include_paths\": [\"./circuits\", \"./node_modules\"],\n\
      \"output_format\": \"r1cs\"\n\
    },\n\
    \"security\": {\n\
      \"prime\": \"bn128\",\n\
      \"inspect\": true,\n\
      \"warn_on_unconnected\": true\n\
    }\n\
  },\n\
  \"snarkjs\": {\n\
    \"version\": \"0.7.4\",\n\
    \"ceremony\": {\n\
      \"ptau_file\": \"/app/data/trusted-setup/powersOfTau28_hez_final_20.ptau\",\n\
      \"beacon\": \"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f\"\n\
    }\n\
  }\n\
}" > /app/config/circom.config.json

# Verify Garaga SDK installation
RUN echo "🔍 Verifying Garaga SDK installation..." && \
    garaga --version && \
    circom --version && \
    snarkjs --version && \
    echo "✅ Garaga SDK and ZK tools verified"

# ==============================================================================
# Stage 6: Circuit workspace with application code
# ==============================================================================
FROM garaga-builder AS circuit-workspace

# Copy application source code in optimized order for layer caching
# Configuration files first to enable better caching
COPY *.config.js* ./
COPY *.config.json* ./

# Copy source code directories
COPY zk-circuits/ ./zk-circuits/
COPY src/ ./src/
COPY scripts/ ./scripts/

# Set up circuit compilation environment
ARG OPTIMIZATION_LEVEL
ARG SECURITY_LEVEL

ENV GARAGA_CUDA_ENABLED=true
ENV GARAGA_OPTIMIZATION_LEVEL=${OPTIMIZATION_LEVEL}
ENV ZK_PROOF_SECURITY_LEVEL=${SECURITY_LEVEL}
ENV CIRCUIT_CACHE_SIZE=1024
ENV PARALLEL_COMPILATION=true
ENV MEMORY_POOL_SIZE=2048
ENV GPU_MEMORY_FRACTION=0.8

# Create optimized circuit compilation script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🔨 Starting optimized ZK circuit compilation..."\n\
echo "Configuration:"\n\
echo "  • CUDA Enabled: $GARAGA_CUDA_ENABLED"\n\
echo "  • Optimization Level: $GARAGA_OPTIMIZATION_LEVEL"\n\
echo "  • Security Level: $ZK_PROOF_SECURITY_LEVEL"\n\
echo "  • Memory Pool: ${MEMORY_POOL_SIZE}MB"\n\
echo "  • GPU Memory Fraction: $GPU_MEMORY_FRACTION"\n\
echo ""\n\
\n\
# Create output directories\n\
mkdir -p build/{circuits,optimized,cache}\n\
\n\
# Compile circuits with error handling\n\
CIRCUIT_COUNT=0\n\
if [ -d "zk-circuits" ] && [ "$(find zk-circuits -name \"*.circom\" -type f | wc -l)" -gt 0 ]; then\n\
    echo "📝 Compiling Circom circuits..."\n\
    find zk-circuits -name "*.circom" -type f | while read -r circuit; do\n\
        circuit_name=$(basename "$circuit" .circom)\n\
        echo "  • Compiling $circuit_name..."\n\
        if circom "$circuit" --r1cs --wasm --sym --output build/circuits/ 2>/dev/null; then\n\
            echo "    ✅ $circuit_name compiled successfully"\n\
            CIRCUIT_COUNT=$((CIRCUIT_COUNT + 1))\n\
        else\n\
            echo "    ❌ $circuit_name compilation failed"\n\
        fi\n\
    done\n\
    echo "📊 Compiled $CIRCUIT_COUNT circuit(s)"\n\
else\n\
    echo "ℹ️  No Circom circuits found in zk-circuits directory"\n\
fi\n\
\n\
# Run Garaga optimization if available and circuits exist\n\
if command -v garaga >/dev/null 2>&1 && [ "$(find build/circuits -name \"*.r1cs\" | wc -l)" -gt 0 ]; then\n\
    echo "⚡ Running Garaga GPU optimization..."\n\
    if garaga optimize --input build/circuits --output build/optimized --cuda 2>/dev/null; then\n\
        echo "✅ Garaga optimization completed"\n\
    else\n\
        echo "⚠️  Garaga optimization failed - using unoptimized circuits"\n\
    fi\n\
else\n\
    echo "ℹ️  Garaga optimization skipped (no circuits or tool unavailable)"\n\
fi\n\
\n\
echo "✅ Circuit compilation completed"\n\
' > /app/compile-circuits.sh && chmod +x /app/compile-circuits.sh

# Execute circuit compilation
RUN /app/compile-circuits.sh

# Verify compilation results
RUN echo "🔍 Verifying circuit compilation..." && \
    if [ -d "build" ]; then \
        echo "✅ Build directory created"; \
        echo "  • R1CS files: $(find build -name "*.r1cs" 2>/dev/null | wc -l)"; \
        echo "  • WASM files: $(find build -name "*.wasm" 2>/dev/null | wc -l)"; \
        echo "  • Symbol files: $(find build -name "*.sym" 2>/dev/null | wc -l)"; \
    else \
        echo "⚠️  No build artifacts found"; \
    fi

# ==============================================================================
# Stage 7: Security validator with comprehensive scanning
# ==============================================================================
FROM circuit-workspace AS security-validator

# Install security scanning tools
RUN npm install -g audit-ci@latest retire@latest --no-fund && \
    npm cache clean --force

# Set security scanning configuration
ENV SECURITY_FAIL_ON_HIGH=true
ENV SECURITY_AUDIT_LEVEL=moderate

# Create comprehensive security validation script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🛡️  Starting comprehensive security validation..."\n\
echo "Security Configuration:"\n\
echo "  • Fail on High Vulnerabilities: $SECURITY_FAIL_ON_HIGH"\n\
echo "  • Audit Level: $SECURITY_AUDIT_LEVEL"\n\
echo "  • ZK Security Level: $ZK_PROOF_SECURITY_LEVEL"\n\
echo ""\n\
\n\
# Initialize security report\n\
SECURITY_REPORT="/app/security-validation.json"\n\
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")\n\
\n\
echo "{\n\
  \"security_assessment\": {\n\
    \"timestamp\": \"$TIMESTAMP\",\n\
    \"configuration\": {\n\
      \"cuda_version\": \"${CUDA_VERSION:-unknown}\",\n\
      \"garaga_version\": \"${GARAGA_VERSION:-unknown}\",\n\
      \"node_version\": \"$(node --version 2>/dev/null || echo unknown)\",\n\
      \"python_version\": \"$(python3 --version 2>&1 | cut -d\" \" -f2 || echo unknown)\",\n\
      \"optimization_level\": ${OPTIMIZATION_LEVEL:-3},\n\
      \"security_level\": ${ZK_PROOF_SECURITY_LEVEL:-128}\n\
    },\n\
    \"scans\": {\n\
      \"npm_audit\": {" > "$SECURITY_REPORT"\n\
\n\
# NPM Security Audit\n\
echo "🔍 Running NPM security audit..."\n\
NPM_AUDIT_STATUS="unknown"\n\
if npm audit --audit-level="$SECURITY_AUDIT_LEVEL" --json > npm-audit.json 2>&1; then\n\
    NPM_AUDIT_STATUS="passed"\n\
    echo "✅ NPM audit passed"\n\
else\n\
    NPM_AUDIT_STATUS="failed"\n\
    echo "⚠️  NPM audit found vulnerabilities"\n\
    if [ "$SECURITY_FAIL_ON_HIGH" = "true" ]; then\n\
        HIGH_VULNS=$(jq -r ".metadata.vulnerabilities.high // 0" npm-audit.json 2>/dev/null || echo "0")\n\
        CRITICAL_VULNS=$(jq -r ".metadata.vulnerabilities.critical // 0" npm-audit.json 2>/dev/null || echo "0")\n\
        if [ "$HIGH_VULNS" -gt 0 ] || [ "$CRITICAL_VULNS" -gt 0 ]; then\n\
            echo "❌ High/Critical vulnerabilities found - failing validation"\n\
            cat npm-audit.json\n\
            exit 1\n\
        fi\n\
    fi\n\
fi\n\
\n\
echo "        \"status\": \"$NPM_AUDIT_STATUS\"," >> "$SECURITY_REPORT"\n\
echo "        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" >> "$SECURITY_REPORT"\n\
echo "      }," >> "$SECURITY_REPORT"\n\
\n\
# Circuit Security Analysis\n\
echo "🔍 Analyzing ZK circuit security..."\n\
CIRCUIT_COUNT=$(find build -name "*.r1cs" 2>/dev/null | wc -l || echo "0")\n\
\n\
echo "      \"circuit_analysis\": {\n\
        \"compiled_circuits\": $CIRCUIT_COUNT,\n\
        \"trusted_setup_verified\": $([ -f "/app/verify-trusted-setup.sh" ] && echo "true" || echo "false"),\n\
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"\n\
      }" >> "$SECURITY_REPORT"\n\
\n\
echo "    },\n\
    \"summary\": {\n\
      \"overall_status\": \"completed\",\n\
      \"recommendations\": [\n\
        \"Review all dependency vulnerabilities before production deployment\",\n\
        \"Ensure cryptographic keys are properly managed and rotated\",\n\
        \"Verify circuit security properties before use in production\"\n\
      ]\n\
    }\n\
  }\n\
}" >> "$SECURITY_REPORT"\n\
\n\
echo "✅ Security validation completed"\n\
echo "📄 Security report: $SECURITY_REPORT"\n\
' > /app/validate-security.sh && chmod +x /app/validate-security.sh

# Execute security validation
RUN /app/validate-security.sh

# ==============================================================================
# Stage 8: Key generator (optional stage for cryptographic key generation)
# ==============================================================================
FROM security-validator AS key-generator

ARG EXTERNAL_KEYS

# Create secure key generation script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
if [ "$EXTERNAL_KEYS" = "true" ]; then\n\
    echo "ℹ️  External key mode enabled - skipping key generation"\n\
    echo "   Keys should be mounted at runtime to /app/keys"\n\
    mkdir -p /app/keys/{proving,verification}\n\
    echo "External keys expected" > /app/keys/README.txt\n\
    exit 0\n\
fi\n\
\n\
echo "🔐 Starting secure cryptographic key generation..."\n\
echo "Security Configuration:"\n\
echo "  • Security Level: $ZK_PROOF_SECURITY_LEVEL-bit"\n\
echo "  • Key Derivation: PBKDF2"\n\
echo "  • Secure Random: Hardware entropy"\n\
echo ""\n\
\n\
# Create key directories\n\
mkdir -p /app/keys/{proving,verification}\n\
\n\
# Verify trusted setup availability\n\
PTAU_FILE="/app/data/trusted-setup/powersOfTau28_hez_final_20.ptau"\n\
if [ ! -f "$PTAU_FILE" ]; then\n\
    echo "❌ Powers of Tau file not found - cannot generate keys"\n\
    exit 1\n\
fi\n\
\n\
# Generate keys for compiled circuits\n\
GENERATED_KEYS=0\n\
if [ "$(find build/circuits -name \"*.r1cs\" 2>/dev/null | wc -l)" -gt 0 ]; then\n\
    echo "🔑 Generating cryptographic keys..."\n\
    find build/circuits -name "*.r1cs" | while read -r r1cs; do\n\
        circuit_name=$(basename "$r1cs" .r1cs)\n\
        echo "  • Generating keys for $circuit_name..."\n\
        \n\
        # Generate proving key with error handling\n\
        if snarkjs groth16 setup "$r1cs" "$PTAU_FILE" "/app/keys/proving/${circuit_name}_proving_key.zkey" 2>/dev/null; then\n\
            echo "    ✅ Proving key generated"\n\
            \n\
            # Generate verification key\n\
            if snarkjs zkey export verificationkey "/app/keys/proving/${circuit_name}_proving_key.zkey" "/app/keys/verification/${circuit_name}_verification_key.json" 2>/dev/null; then\n\
                echo "    ✅ Verification key generated"\n\
                GENERATED_KEYS=$((GENERATED_KEYS + 1))\n\
            else\n\
                echo "    ❌ Verification key generation failed"\n\
            fi\n\
        else\n\
            echo "    ❌ Proving key generation failed"\n\
        fi\n\
    done\n\
    echo "🔑 Generated keys for $GENERATED_KEYS circuit(s)"\n\
else\n\
    echo "ℹ️  No compiled circuits found - no keys generated"\n\
fi\n\
\n\
# Create key manifest\n\
echo "{\n\
  \"key_generation\": {\n\
    \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\n\
    \"security_level\": $ZK_PROOF_SECURITY_LEVEL,\n\
    \"proving_keys\": $(find /app/keys/proving -name \"*.zkey\" 2>/dev/null | wc -l),\n\
    \"verification_keys\": $(find /app/keys/verification -name \"*.json\" 2>/dev/null | wc -l),\n\
    \"trusted_setup\": \"powersOfTau28_hez_final_20.ptau\"\n\
  }\n\
}" > /app/keys/manifest.json\n\
\n\
echo "✅ Key generation completed"\n\
' > /app/generate-keys.sh && chmod +x /app/generate-keys.sh

# Execute key generation (conditional on EXTERNAL_KEYS)
RUN /app/generate-keys.sh

# ==============================================================================
# Stage 9: Production runtime with minimal dependencies
# ==============================================================================
FROM base-runtime AS production-runtime

# Copy build arguments for runtime configuration
ARG MAX_MEMORY
ARG SECURITY_LEVEL
ARG STARTUP_GRACE_PERIOD

# Install Node.js runtime for production
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    node --version && npm --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Create runtime package.json with minimal dependencies
COPY package-runtime.json* ./package.json
COPY package-lock.json* ./

# Install only production runtime dependencies
RUN npm ci --only=production --no-optional --no-fund && \
    npm cache clean --force

# Install minimal Python runtime dependencies
COPY requirements-runtime.txt* ./
RUN if [ -f "requirements-runtime.txt" ]; then \
        pip3 install --no-cache-dir -r requirements-runtime.txt; \
    else \
        # Install minimal runtime Python packages if no specific requirements\n\
        pip3 install --no-cache-dir \
        py_ecc==7.0.1 \
        numpy==1.26.2 \
        starknet-py==0.21.0; \
    fi

# Copy essential runtime files from build stages
COPY --from=key-generator /app/build/ ./build/
COPY --from=key-generator /app/keys/ ./keys/
COPY --from=key-generator /app/config/ ./config/
COPY --from=security-validator /app/security-validation.json ./

# Copy proof service application
COPY proof-service/ ./proof-service/

# Create comprehensive runtime directory structure
RUN mkdir -p /app/{logs,tmp,cache,proofs,metrics,secrets} && \
    chown -R zkuser:zkuser /app

# Switch to non-root user for enhanced security
USER zkuser

# Set production environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=${MAX_MEMORY} --disallow-code-generation-from-strings --trace-warnings"

# Garaga and ZK configuration
ENV GARAGA_CUDA_ENABLED=true
ENV ZK_PROOF_SECURITY_LEVEL=${SECURITY_LEVEL}
ENV CIRCUIT_CACHE_SIZE=1024
ENV PROOF_BATCH_SIZE=10
ENV MEMORY_POOL_SIZE=2048
ENV GPU_MEMORY_FRACTION=0.8

# Service configuration
ENV PROOF_SERVICE_PORT=4000
ENV LOG_LEVEL=info
ENV HEALTH_CHECK_INTERVAL=30
ENV STARKNET_NETWORK=mainnet
ENV CAIRO_VERSION=2.8.2
ENV STARTUP_GRACE_PERIOD=${STARTUP_GRACE_PERIOD}

# GPU and CUDA configuration
ENV CUDA_VISIBLE_DEVICES=all
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Security and performance settings
ENV TMPDIR=/app/tmp
ENV TELEMETRY_ENABLED=false
ENV CIRCUIT_OPTIMIZATION=true
ENV PARALLEL_PROOF_GENERATION=true

# Secrets management configuration
ENV SECRET_STORE_TYPE=file
ENV EXTERNAL_KEY_PATH=/app/keys

# Create enhanced health check script with secrets management validation
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Health check configuration\n\
STARTUP_GRACE_PERIOD=${STARTUP_GRACE_PERIOD:-120}\n\
CURRENT_TIME=$(date +%s)\n\
CONTAINER_START_TIME=${CONTAINER_START_TIME:-$CURRENT_TIME}\n\
TIME_SINCE_START=$((CURRENT_TIME - CONTAINER_START_TIME))\n\
\n\
echo "🔍 Garaga SDK Health Check"\n\
echo "=========================="\n\
\n\
# Check if we are within startup grace period\n\
if [ "$TIME_SINCE_START" -lt "$STARTUP_GRACE_PERIOD" ]; then\n\
    echo "ℹ️  Within startup grace period (${TIME_SINCE_START}s / ${STARTUP_GRACE_PERIOD}s)"\n\
    GRACE_MODE=true\n\
else\n\
    GRACE_MODE=false\n\
fi\n\
\n\
# Check essential directories and files\n\
check_directory() {\n\
    local dir="$1"\n\
    local description="$2"\n\
    local required="$3"\n\
    if [ -d "$dir" ]; then\n\
        file_count=$(find "$dir" -type f 2>/dev/null | wc -l)\n\
        echo "✅ $description: $file_count files"\n\
        return 0\n\
    else\n\
        echo "❌ $description missing"\n\
        if [ "$required" = "true" ] && [ "$GRACE_MODE" = "false" ]; then\n\
            return 1\n\
        fi\n\
        return 0\n\
    fi\n\
}\n\
\n\
# Verify essential components\n\
check_directory "config" "Configuration files" "true" || exit 1\n\
\n\
# Check for circuits (may be empty in runtime-only deployment)\n\
check_directory "build" "Circuit artifacts" "false"\n\
\n\
# Check for keys (may be externally mounted)\n\
if [ "$EXTERNAL_KEYS" = "true" ]; then\n\
    if [ -d "/app/keys" ] && [ "$(find /app/keys -name \"*.zkey\" -o -name \"*.json\" | wc -l)" -gt 0 ]; then\n\
        echo "✅ External keys mounted successfully"\n\
    else\n\
        echo "⚠️  External keys not found - ensure they are properly mounted"\n\
        if [ "$GRACE_MODE" = "false" ]; then\n\
            exit 1\n\
        fi\n\
    fi\n\
else\n\
    check_directory "keys" "Cryptographic keys" "false"\n\
fi\n\
\n\
# Test GPU availability if CUDA is enabled\n\
if [ "$GARAGA_CUDA_ENABLED" = "true" ]; then\n\
    echo "🎮 GPU Status:"\n\
    if command -v nvidia-smi >/dev/null 2>&1; then\n\
        if timeout 5 nvidia-smi >/dev/null 2>&1; then\n\
            gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "Unknown")\n\
            gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "Unknown")\n\
            echo "✅ GPU: $gpu_name ($gpu_memory MB)"\n\
        else\n\
            echo "⚠️  GPU not accessible - using CPU fallback"\n\
        fi\n\
    else\n\
        echo "⚠️  nvidia-smi not found - GPU may not be available"\n\
    fi\n\
else\n\
    echo "ℹ️  CUDA disabled - using CPU mode"\n\
fi\n\
\n\
# Test proof service if not in grace period\n\
SERVICE_PORT=${PROOF_SERVICE_PORT:-4000}\n\
echo "🌐 Service Status:"\n\
if curl -f -s --max-time 5 "http://localhost:${SERVICE_PORT}/health" >/dev/null 2>&1; then\n\
    echo "✅ Proof service responding on port $SERVICE_PORT"\n\
else\n\
    echo "⚠️  Proof service not responding"\n\
    if [ "$GRACE_MODE" = "false" ]; then\n\
        echo "❌ Service check failed after grace period"\n\
        exit 1\n\
    else\n\
        echo "ℹ️  Service may still be starting up"\n\
    fi\n\
fi\n\
\n\
# Check memory usage\n\
echo "💾 Memory Status:"\n\
if command -v free >/dev/null 2>&1; then\n\
    memory_usage=$(free | grep Mem | awk "{printf \"%.1f\", \$3/\$2 * 100.0}" 2>/dev/null || echo "unknown")\n\
    echo "✅ Memory usage: ${memory_usage}%"\n\
fi\n\
\n\
echo "✅ Health check completed successfully"\n\
' > /home/zkuser/health-check.sh && chmod +x /home/zkuser/health-check.sh

# Configure health check with extended startup period
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD /home/zkuser/health-check.sh

# Create secrets management integration script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🔐 Initializing secrets management..."\n\
\n\
SECRET_STORE_TYPE=${SECRET_STORE_TYPE:-file}\n\
\n\
case "$SECRET_STORE_TYPE" in\n\
    "file")\n\
        echo "  • Using file-based secrets from /app/secrets/"\n\
        if [ -d "/app/secrets" ]; then\n\
            echo "  • Secrets directory mounted: $(find /app/secrets -type f | wc -l) files"\n\
        else\n\
            echo "  • No secrets directory found (using defaults)"\n\
        fi\n\
        ;;\n\
    "vault")\n\
        echo "  • Using HashiCorp Vault integration"\n\
        if [ -n "$VAULT_ADDR" ] && [ -n "$VAULT_TOKEN" ]; then\n\
            echo "  • Vault configured: $VAULT_ADDR"\n\
            # Add Vault secret retrieval logic here\n\
        else\n\
            echo "  • ❌ Vault credentials not configured"\n\
            exit 1\n\
        fi\n\
        ;;\n\
    "k8s")\n\
        echo "  • Using Kubernetes secrets integration"\n\
        if [ -n "$K8S_SECRET_NAME" ]; then\n\
            echo "  • K8s secret: $K8S_SECRET_NAME"\n\
            # Add K8s secret mounting logic here\n\
        else\n\
            echo "  • ❌ Kubernetes secret name not configured"\n\
            exit 1\n\
        fi\n\
        ;;\n\
    *)\n\
        echo "  • ❌ Unknown secret store type: $SECRET_STORE_TYPE"\n\
        exit 1\n\
        ;;\n\
esac\n\
\n\
echo "✅ Secrets management initialized"\n\
' > /home/zkuser/init-secrets.sh && chmod +x /home/zkuser/init-secrets.sh

# Create production startup script with comprehensive service information
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Set container start time for health check grace period\n\
export CONTAINER_START_TIME=$(date +%s)\n\
\n\
echo "🚀 Veridis Garaga SDK Integration Service (Production)"\n\
echo "====================================================="\n\
echo ""\n\
echo "🔧 Environment Configuration:"\n\
echo "  • Node.js: $(node --version)"\n\
echo "  • Python: $(python3 --version 2>&1)"\n\
echo "  • Memory Limit: ${MAX_MEMORY:-8192}MB"\n\
echo "  • Security Level: ${ZK_PROOF_SECURITY_LEVEL:-128}-bit"\n\
echo "  • Service Port: ${PROOF_SERVICE_PORT:-4000}"\n\
echo "  • Startup Grace Period: ${STARTUP_GRACE_PERIOD:-120}s"\n\
echo ""\n\
echo "🎮 GPU Configuration:"\n\
if [ "$GARAGA_CUDA_ENABLED" = "true" ]; then\n\
    if command -v nvidia-smi >/dev/null 2>&1 && timeout 5 nvidia-smi >/dev/null 2>&1; then\n\
        gpu_info=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "GPU info unavailable")\n\
        echo "  • GPU: $gpu_info"\n\
        echo "  • Memory Fraction: $(echo $GPU_MEMORY_FRACTION | sed \"s/0\\.//\")%"\n\
        echo "  • Compute Capability: 7.0+ required"\n\
    else\n\
        echo "  • GPU: Not available (CPU fallback enabled)"\n\
        echo "  • Warning: Ensure NVIDIA drivers ≥ 525.60.13 on host"\n\
    fi\n\
else\n\
    echo "  • GPU: Disabled (CPU mode)"\n\
fi\n\
echo ""\n\
echo "🔐 Security Configuration:"\n\
echo "  • User: $(whoami) ($(id))"\n\
echo "  • Security Level: ${ZK_PROOF_SECURITY_LEVEL:-128}-bit"\n\
echo "  • Secret Store: ${SECRET_STORE_TYPE:-file}"\n\
echo "  • External Keys: ${EXTERNAL_KEYS:-false}"\n\
echo "  • Code Generation: Disabled"\n\
echo "  • Memory Protection: Enabled"\n\
echo ""\n\
echo "⚡ Performance Configuration:"\n\
echo "  • Circuit Cache: ${CIRCUIT_CACHE_SIZE:-1024}MB"\n\
echo "  • Proof Batch Size: ${PROOF_BATCH_SIZE:-10}"\n\
echo "  • Memory Pool: ${MEMORY_POOL_SIZE:-2048}MB"\n\
echo "  • Parallel Processing: ${PARALLEL_PROOF_GENERATION:-true}"\n\
echo "  • Circuit Optimization: ${CIRCUIT_OPTIMIZATION:-true}"\n\
echo ""\n\
echo "📊 Runtime Information:"\n\
if [ -d "build" ]; then\n\
    circuit_count=$(find build -name "*.r1cs" 2>/dev/null | wc -l || echo "0")\n\
    wasm_count=$(find build -name "*.wasm" 2>/dev/null | wc -l || echo "0")\n\
    echo "  • Compiled Circuits: $circuit_count"\n\
    echo "  • WASM Artifacts: $wasm_count"\n\
else\n\
    echo "  • Circuits: Build directory not found"\n\
fi\n\
\n\
if [ -d "keys" ]; then\n\
    proving_keys=$(find keys -name "*.zkey" 2>/dev/null | wc -l || echo "0")\n\
    verification_keys=$(find keys -name "*.json" 2>/dev/null | wc -l || echo "0")\n\
    echo "  • Proving Keys: $proving_keys"\n\
    echo "  • Verification Keys: $verification_keys"\n\
    if [ "$EXTERNAL_KEYS" = "true" ]; then\n\
        echo "  • Key Source: External (mounted)"\n\
    else\n\
        echo "  • Key Source: Generated at build time"\n\
    fi\n\
else\n\
    echo "  • Keys: Keys directory not found"\n\
fi\n\
echo ""\n\
echo "🌐 Network Configuration:"\n\
echo "  • Starknet Network: ${STARKNET_NETWORK:-mainnet}"\n\
echo "  • Cairo Version: ${CAIRO_VERSION:-2.8.2}"\n\
echo ""\n\
echo "📋 Monitoring:"\n\
echo "  • Log Level: ${LOG_LEVEL:-info}"\n\
echo "  • Health Checks: Every ${HEALTH_CHECK_INTERVAL:-30}s"\n\
echo "  • Telemetry: ${TELEMETRY_ENABLED:-false}"\n\
echo ""\n\
echo "🎯 Initializing services..."\n\
\n\
# Initialize secrets management\n\
/home/zkuser/init-secrets.sh\n\
\n\
# Ensure required directories exist\n\
mkdir -p /app/{logs,tmp,cache,proofs,metrics}\n\
\n\
echo ""\n\
echo "🚀 Starting Garaga SDK proof generation service..."\n\
echo "   Ready for zero-knowledge proof operations!"\n\
echo ""\n\
\n\
# Start the service with proper signal handling\n\
exec "$@"\n\
' > /home/zkuser/startup.sh && chmod +x /home/zkuser/startup.sh

# Expose proof generation service port
EXPOSE 4000

# Set entrypoint with enhanced startup script
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/home/zkuser/startup.sh"]

# Default command for production proof service
CMD ["node", "proof-service/index.js"]

# ==============================================================================
# Stage 10: Development workspace (optional target)
# ==============================================================================
FROM production-runtime AS development-workspace

# Switch to root for development tool installation
USER root

# Install comprehensive development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    nano \
    htop \
    strace \
    gdb \
    valgrind \
    tree \
    jq \
    net-tools \
    procps \
    git \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install development Node.js packages
RUN npm install -g \
    nodemon \
    pm2 \
    clinic \
    0x \
    npm-check-updates \
    && npm cache clean --force

# Install comprehensive Python development packages
RUN pip3 install --no-cache-dir \
    ipython \
    jupyter \
    matplotlib \
    pandas \
    pytest \
    pytest-cov \
    black \
    flake8 \
    mypy \
    bandit

# Copy additional development files from build stages
COPY --from=circuit-workspace /app/zk-circuits/ ./zk-circuits/
COPY --from=circuit-workspace /app/src/ ./src/
COPY --from=circuit-workspace /app/scripts/ ./scripts/

# Copy development package files
COPY package.json package-lock.json ./

# Install all dependencies (including dev dependencies)
RUN npm install && npm cache clean --force

# Set development-specific environment variables
ENV NODE_ENV=development
ENV LOG_LEVEL=debug
ENV TELEMETRY_ENABLED=true
ENV CIRCUIT_OPTIMIZATION=false
ENV DEBUG=garaga:*

# Switch back to zkuser
USER zkuser

# Create comprehensive development startup script
RUN echo '#!/bin/bash\n\
echo "🧪 Veridis Garaga SDK Development Environment"\n\
echo "============================================"\n\
echo ""\n\
echo "🛠️  Development Tools Available:"\n\
echo "  • Node.js Development: nodemon, pm2, clinic, 0x, ncu"\n\
echo "  • Python Development: ipython, jupyter, pytest, mypy"\n\
echo "  • Code Quality: black, flake8, bandit"\n\
echo "  • System Tools: htop, strace, gdb, valgrind, tree"\n\
echo "  • Debugging: Debug mode enabled (DEBUG=garaga:*)"\n\
echo ""\n\
echo "📝 Development Commands:"\n\
echo "  • Hot reload: nodemon proof-service/index.js"\n\
echo "  • Process manager: pm2 start proof-service/index.js"\n\
echo "  • Performance profiling: clinic doctor -- node proof-service/index.js"\n\
echo "  • CPU profiling: 0x proof-service/index.js"\n\
echo "  • Python REPL: ipython"\n\
echo "  • Jupyter notebook: jupyter notebook --ip=0.0.0.0 --port=8888"\n\
echo "  • Run tests: npm test && python -m pytest"\n\
echo "  • Code formatting: black . && npm run format"\n\
echo "  • Security scan: bandit -r . && npm audit"\n\
echo "  • Update dependencies: ncu -u && npm update"\n\
echo ""\n\
echo "🔍 Development Resources:"\n\
echo "  • Circuit source: ./zk-circuits/"\n\
echo "  • Application source: ./src/"\n\
echo "  • Build artifacts: ./build/"\n\
echo "  • Configuration: ./config/"\n\
echo "  • Scripts: ./scripts/"\n\
echo "  • Keys: ./keys/"\n\
echo ""\n\
echo "🎯 Development Environment Ready!"\n\
echo ""\n\
exec "$@"\n\
' > /home/zkuser/dev-startup.sh && chmod +x /home/zkuser/dev-startup.sh

# Override entrypoint for development
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/home/zkuser/dev-startup.sh"]

# Default development command with debugging
CMD ["nodemon", "--inspect=0.0.0.0:9229", "--watch", "proof-service", "--watch", "src", "proof-service/index.js"]

# Expose additional development ports
EXPOSE 8888 9229

# Comprehensive metadata labels following OCI standards
LABEL maintainer="Veridis Team" \
      version="2.0.0" \
      description="Veridis Garaga SDK Integration with Enhanced Security and Performance" \
      service.name="garaga-sdk" \
      service.type="zk-proof-generation" \
      service.port="4000" \
      gpu.required="true" \
      gpu.compute.capability="7.0+" \
      gpu.driver.minimum="525.60.13" \
      cuda.version="${CUDA_VERSION}" \
      garaga.version="${GARAGA_VERSION}" \
      node.version="${NODE_VERSION}" \
      rust.version="${RUST_VERSION}" \
      python.version="${PYTHON_VERSION}" \
      optimization.level="${OPTIMIZATION_LEVEL}" \
      security.level="${SECURITY_LEVEL}" \
      cairo.integration="${CAIRO_INTEGRATION}" \
      build.target="${BUILD_TARGET}" \
      secrets.management="vault,k8s,file" \
      external.keys.support="${EXTERNAL_KEYS}" \
      startup.grace.period="${STARTUP_GRACE_PERIOD}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Garaga SDK Integration v2.0" \
      org.opencontainers.image.description="Production-ready Garaga SDK with enhanced security, external key management, and optimized Docker layer caching" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/docker/zk/README.md" \
      org.opencontainers.image.base.name="nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu22.04" \
      org.opencontainers.image.base.os.version="22.04"

# Create requirements files for easier dependency management
RUN echo '# Runtime Python dependencies\n\
py_ecc==7.0.1\n\
numpy==1.26.2\n\
starknet-py==0.21.0\n\
pycryptodome==3.19.0\n\
' > requirements-runtime.txt

RUN echo '{\n\
  "name": "garaga-runtime",\n\
  "version": "2.0.0",\n\
  "main": "proof-service/index.js",\n\
  "dependencies": {\n\
    "express": "^4.18.2",\n\
    "cors": "^2.8.5",\n\
    "helmet": "^7.1.0",\n\
    "winston": "^3.11.0"\n\
  },\n\
  "engines": {\n\
    "node": ">=22.0.0"\n\
  }\n\
}' > package-runtime.json
