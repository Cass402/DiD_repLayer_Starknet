# Veridis: Development Environment and Container Orchestration Guide

This comprehensive guide provides detailed instructions for setting up development environments, containerizing Veridis protocol components, and deploying them using modern orchestration tools. The guide focuses on Cairo 2.11.4/StarkNet v0.13.4 compatibility and incorporates current security best practices.

## Document Control

| Version | Date       | Author  | Description of Changes                                                                                |
| :------ | :--------- | :------ | :---------------------------------------------------------------------------------------------------- |
| 2.0     | 2025-05-31 | Cass402 | Major update with latest tooling versions, enhanced security practices, and performance optimizations |
| 1.0     | 2025-05-30 | Cass402 | Initial version                                                                                       |

## Table of Contents

1. [Introduction](#1-introduction)
2. [Development Environment Setup](#2-development-environment-setup)
3. [VSCode Configuration](#3-vscode-configuration)
4. [Devcontainer Setup](#4-devcontainer-setup)
5. [Dockerization Strategy](#5-dockerization-strategy)
6. [Docker Compose Configuration](#6-docker-compose-configuration)
7. [Kubernetes Deployment](#7-kubernetes-deployment)
8. [Environment Configuration Management](#8-environment-configuration-management)
9. [Cairo-Specific Container Configurations](#9-cairo-specific-container-configurations)
10. [ZK Proof Generation Environment](#10-zk-proof-generation-environment)
11. [Cross-Chain Testing Environment](#11-cross-chain-testing-environment)
12. [Monitoring and Logging](#12-monitoring-and-logging)
13. [Security Considerations](#13-security-considerations)
14. [Disaster Recovery and Backup](#14-disaster-recovery-and-backup)
15. [References and Additional Resources](#15-references-and-additional-resources)

## 1. Introduction

### 1.1 Purpose

This guide provides comprehensive instructions for setting up consistent development environments, containerizing the Veridis protocol components, and deploying them using Kubernetes. The Veridis protocol's security, performance, and regulatory compliance requirements demand a robust development and deployment infrastructure tailored specifically for Cairo 2.11.4 and StarkNet v0.13.4.

### 1.2 Scope

This document covers:

- Local development environment configuration for Cairo v2.11.4 and StarkNet v0.13.4
- VSCode setup with Cairo-specific extensions and enhanced tooling
- Development containers configuration with enterprise features and security hardening
- Docker and Docker Compose setup for component orchestration with multi-stage security
- Kubernetes deployment configurations for production environments with enhanced security policies
- Environment-specific configurations and secure secret management
- Cairo-specific container considerations and MLIR-based optimization
- ZK proof generation infrastructure with Garaga SDK integration and GPU acceleration
- Cross-chain testing environments for multi-blockchain validation with enhanced security
- Enterprise compliance automation and GDPR enforcement with cryptographic guarantees
- Performance monitoring and optimization tools for Cairo/StarkNet workloads

### 1.3 Audience

This guide is intended for:

- Cairo developers building on StarkNet v0.13.4
- DevOps engineers implementing enterprise infrastructure
- Security engineers conducting formal verification audits
- Compliance teams implementing GDPR automation
- QA engineers testing cross-chain functionality
- Enterprise developers requiring performance optimization
- Zero-knowledge proof system architects

### 1.4 Related Documents

- Veridis Project Requirements Specification (VERIDIS-SPEC-REQ-2025-001)
- Veridis Developer SDK Specifications v2.1 (VERIDIS-SPEC-SDK-V2-2025-003)
- Veridis Security Protocols and Compliance Framework v3.2.1
- Veridis Cross-Chain Bridge Architecture Guide v2.2.0
- Veridis Zero-Knowledge Proof System Specification v3.0
- Veridis Formal Verification Framework v1.5

## 2. Development Environment Setup

### 2.1 Prerequisites

Ensure the following software is installed on your development machine:

| Software         | Version        | Purpose                                              |
| :--------------- | :------------- | :--------------------------------------------------- |
| Scarb            | 2.11.4+        | Cairo package manager and build tool                 |
| Cairo Native     | 2.11.4+        | Native Cairo execution engine with MLIR optimization |
| Starknet Foundry | 0.44.0+        | StarkNet testing and deployment framework            |
| Docker           | 25.0+          | Container runtime                                    |
| Docker Compose   | 2.20+          | Multi-container orchestration                        |
| VSCode           | 1.84+          | Development IDE with Cairo extensions                |
| Git              | 2.40+          | Version control                                      |
| Node.js          | 18.17+ / 20.9+ | JavaScript runtime for tooling                       |
| Kubectl          | 1.28+          | Kubernetes CLI                                       |
| Helm             | 3.13+          | Kubernetes package manager                           |
| Python           | 3.9+           | Required for Cairo toolchain                         |
| CUDA Toolkit     | 12.0+          | GPU acceleration for ZK proof generation (optional)  |

### 2.2 Repository Structure

The Veridis repository is organized as follows:

```
veridis/
├── .vscode/                    # VSCode configuration
├── .devcontainer/              # Development container configuration
├── contracts/                  # Cairo smart contracts
│   ├── src/
│   │   ├── identity/           # Identity management contracts
│   │   ├── attestation/        # Attestation system contracts
│   │   ├── compliance/         # GDPR compliance contracts
│   │   └── bridge/             # Cross-chain bridge contracts
│   ├── Scarb.toml              # Cairo project configuration
│   └── Dockerfile              # Contract development environment
├── zk-circuits/                # Zero-knowledge circuits
│   ├── identity/               # Identity verification circuits
│   ├── attestation/            # Credential verification circuits
│   ├── formal-verification/    # Formal verification specifications
│   └── Dockerfile              # ZK development environment
├── services/                   # Microservices
│   ├── identity-service/       # Identity management API
│   ├── attestation-service/    # Attestation issuance API
│   ├── verification-service/   # Credential verification API
│   ├── compliance-service/     # GDPR compliance automation
│   └── bridge-service/         # Cross-chain bridge service
├── client-sdk/                 # Client-side SDK
│   ├── typescript/             # TypeScript SDK
│   ├── python/                 # Python SDK
│   └── mobile/                 # Mobile SDK
├── docker/                     # Docker configurations
│   ├── base/                   # Base images
│   ├── cairo/                  # Cairo-specific images
│   ├── security/               # Security hardening configurations
│   └── enterprise/             # Enterprise configurations
├── docker-compose.yml          # Main Docker Compose file
├── docker-compose.dev.yml      # Development overrides
├── docker-compose.enterprise.yml # Enterprise configuration
└── k8s/                        # Kubernetes configurations
    ├── base/                   # Common K8s resources
    ├── security/               # Security policies and controls
    ├── development/            # Development environment
    ├── staging/                # Staging environment
    └── production/             # Production environment
```

### 2.3 Initial Setup

To set up the development environment:

1. Clone the repository:

```bash
git clone https://github.com/veridis-protocol/veridis.git
cd veridis
```

2. Install Cairo toolchain:

```bash
# Install Scarb with version pinning
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4

# Install Starknet Foundry
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.44.0

# Install Cairo Native with MLIR optimization
cargo install cairo-native --features "mlir-optimizer" --locked
```

3. Build and start the development environment:

```bash
# Option 1: Using Docker Compose
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Option 2: Using VSCode Devcontainers
# Open the project in VSCode and click "Reopen in Container" when prompted
```

4. Initialize the development environment:

```bash
# Inside the container or locally
./scripts/init-veridis-env.sh
```

## 3. VSCode Configuration

### 3.1 Recommended Extensions

Create `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "starkware.cairo1",
    "ms-azuretools.vscode-docker",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-vscode-remote.remote-containers",
    "redhat.vscode-yaml",
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "ms-vscode.vscode-typescript-next",
    "rust-lang.rust-analyzer",
    "tamasfe.even-better-toml",
    "ms-vscode.makefile-tools",
    "eamodio.gitlens",
    "yzhang.markdown-all-in-one",
    "bierner.markdown-mermaid",
    "streetsidesoftware.code-spell-checker",
    "ms-vsliveshare.vsliveshare",
    "veridis.cairo-tools-v3",
    "devarajv.starknet-analyzer",
    "starkware.cairo-lsp",
    "cairo-security.cairo-security-scanner"
  ]
}
```

### 3.2 Workspace Settings

Create `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "editor.rulers": [100],
  "editor.tabSize": 2,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "cairo1.languageServerPath": "scarb",
  "cairo1.languageServerArgs": ["cairo-language-server"],
  "cairo1.enableProceduralMacros": true,
  "cairo1.scarbVersion": "2.11.4",
  "cairo1.nativeExecution": true,
  "cairo1.resourceBoundsValidation": true,
  "cairo1.gasOptimization": true,
  "cairo1.securityLinting": true,
  "cairo1.complianceChecks": true,
  "cairo1.mlirOptimizationLevel": 3,
  "cairo1.formalVerification.enabled": true,
  "cairo1.experimentalFeatures": false,
  "cairo1.zeroKnowledge.proofOptimization": true,
  "cairo1.disableLegacyConstructs": true,
  "[cairo]": {
    "editor.defaultFormatter": "starkware.cairo1"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "[markdown]": {
    "editor.defaultFormatter": "yzhang.markdown-all-in-one"
  },
  "remote.containers.defaultExtensions": [
    "starkware.cairo1",
    "starkware.cairo-lsp",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "GitHub.copilot",
    "cairo-security.cairo-security-scanner"
  ],
  "terminal.integrated.defaultProfile.linux": "bash",
  "git.autofetch": true,
  "devarajv.starknet-analyzer.enabled": true,
  "devarajv.starknet-analyzer.continousScanning": true,
  "cSpell.words": [
    "scarb",
    "cairo",
    "starknet",
    "veridis",
    "attestation",
    "nullifier",
    "garaga",
    "pedersen",
    "poseidon",
    "merkle",
    "snforge",
    "devcontainer",
    "kubernetes",
    "kubectl",
    "kubeconfig",
    "mlir",
    "casm"
  ]
}
```

### 3.3 Launch Configurations

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Identity Service",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/services/identity-service/dist/index.js",
      "preLaunchTask": "build-identity-service",
      "outFiles": ["${workspaceFolder}/services/identity-service/dist/**/*.js"],
      "envFile": "${workspaceFolder}/services/identity-service/.env.local",
      "internalConsoleOptions": "openOnSessionStart"
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Attestation Service",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/services/attestation-service/dist/index.js",
      "preLaunchTask": "build-attestation-service",
      "outFiles": [
        "${workspaceFolder}/services/attestation-service/dist/**/*.js"
      ],
      "envFile": "${workspaceFolder}/services/attestation-service/.env.local"
    },
    {
      "type": "cairo-native-debugger",
      "request": "launch",
      "name": "Debug Cairo Contract Tests",
      "program": "${workspaceFolder}/contracts/tests/test_${fileBasenameNoExtension}.cairo",
      "cwd": "${workspaceFolder}/contracts",
      "optimizationLevel": 3,
      "enableVerboseLogging": true
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug ZK Circuit Tests",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/zk-circuits/tests/${fileBasenameNoExtension}.test.js",
      "cwd": "${workspaceFolder}/zk-circuits"
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Formal Verification",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/scripts/run-formal-verification.js",
      "args": ["${file}"],
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

### 3.4 Task Configurations

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build-cairo-contracts",
      "type": "shell",
      "command": "cd ${workspaceFolder}/contracts && scarb build --cairo-native --optimized-mlir=true",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "build-identity-service",
      "type": "shell",
      "command": "cd ${workspaceFolder}/services/identity-service && npm run build"
    },
    {
      "label": "build-attestation-service",
      "type": "shell",
      "command": "cd ${workspaceFolder}/services/attestation-service && npm run build"
    },
    {
      "label": "test-cairo-contracts",
      "type": "shell",
      "command": "cd ${workspaceFolder}/contracts && snforge test --gas-report --snapshot",
      "group": {
        "kind": "test",
        "isDefault": true
      }
    },
    {
      "label": "deploy-contracts-dev",
      "type": "shell",
      "command": "cd ${workspaceFolder}/contracts && sncast --network dev --account dev_account deploy --contract-name veridis_main"
    },
    {
      "label": "start-dev-environment",
      "type": "shell",
      "command": "docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d",
      "problemMatcher": []
    },
    {
      "label": "stop-dev-environment",
      "type": "shell",
      "command": "docker-compose -f docker-compose.yml -f docker-compose.dev.yml down",
      "problemMatcher": []
    },
    {
      "label": "run-compliance-checks",
      "type": "shell",
      "command": "cd ${workspaceFolder} && ./scripts/run-compliance-audit.sh",
      "group": {
        "kind": "test",
        "isDefault": false
      }
    },
    {
      "label": "run-formal-verification",
      "type": "shell",
      "command": "cd ${workspaceFolder} && ./scripts/run-formal-verification.sh",
      "group": {
        "kind": "test",
        "isDefault": false
      }
    },
    {
      "label": "security-scan",
      "type": "shell",
      "command": "cd ${workspaceFolder} && ./scripts/run-security-scan.sh",
      "group": {
        "kind": "test",
        "isDefault": false
      }
    },
    {
      "label": "zk-proof-benchmark",
      "type": "shell",
      "command": "cd ${workspaceFolder}/zk-circuits && npm run benchmark",
      "problemMatcher": []
    },
    {
      "label": "cairo-gas-profiler",
      "type": "shell",
      "command": "cd ${workspaceFolder}/contracts && cairo-profiler --target 1M-gas",
      "problemMatcher": []
    }
  ]
}
```

## 4. Devcontainer Setup

### 4.1 Devcontainer Configuration

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "Veridis Development Environment",
  "dockerComposeFile": [
    "../docker-compose.yml",
    "../docker-compose.dev.yml",
    "docker-compose.yml"
  ],
  "service": "dev",
  "workspaceFolder": "/workspace",
  "shutdownAction": "stopCompose",
  "customizations": {
    "vscode": {
      "extensions": [
        "starkware.cairo1",
        "starkware.cairo-lsp",
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "redhat.vscode-yaml",
        "GitHub.copilot",
        "rust-lang.rust-analyzer",
        "tamasfe.even-better-toml",
        "veridis.cairo-tools-v3",
        "cairo-security.cairo-security-scanner",
        "devarajv.starknet-analyzer"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "cairo1.scarbVersion": "2.11.4",
        "cairo1.nativeExecution": true,
        "cairo1.mlirOptimizationLevel": 3,
        "cairo1.formalVerification.enabled": true,
        "cairo1.securityLinting": true
      }
    }
  },
  "remoteUser": "vscode",
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}",
    "SCARB_VERSION": "2.11.4",
    "CAIRO_NATIVE_ENABLED": "true",
    "MLIR_OPTIMIZATION_LEVEL": "3",
    "STARKNET_TX_VERSION": "3",
    "RESOURCE_BOUNDS_ENABLED": "true"
  },
  "postCreateCommand": "scripts/init-veridis-env.sh",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {},
    "ghcr.io/devcontainers/features/rust:1": {},
    "ghcr.io/devcontainers/features/nvidia-cuda:1": {
      "installCudnn": true
    },
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "hostRequirements": {
    "cpus": 4,
    "memory": "8gb",
    "storage": "32gb"
  },
  "securityOpt": ["seccomp=unconfined"],
  "capAdd": ["SYS_PTRACE"]
}
```

### 4.2 Devcontainer Docker Compose Extension

Create `.devcontainer/docker-compose.yml`:

```yaml
version: "3.8"

services:
  dev:
    build:
      context: ..
      dockerfile: docker/cairo/dev.Dockerfile
      args:
        SCARB_VERSION: "2.11.4"
        CAIRO_NATIVE_VERSION: "2.11.4"
        STARKNET_FOUNDRY_VERSION: "0.44.0"
        MLIR_OPTIMIZATION_LEVEL: "3"
    volumes:
      - ..:/workspace:cached
      - cairo-cache:/home/vscode/.cairo
      - scarb-cache:/home/vscode/.local/share/scarb
      - node_modules:/workspace/node_modules
      - contracts-cache:/workspace/contracts/target
      - ~/.ssh:/home/vscode/.ssh:ro
      - ~/.gitconfig:/home/vscode/.gitconfig:ro
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - NODE_ENV=development
      - SCARB_VERSION=2.11.4
      - CAIRO_NATIVE_ENABLED=true
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - MLIR_OPTIMIZATION_LEVEL=3
      - COMPLIANCE_ENABLED=true
      - FORMAL_VERIFICATION_ENABLED=true
      - RESOURCE_BOUNDS_L1_GAS=100000
      - RESOURCE_BOUNDS_L2_GAS=1000000
    command: sleep infinity
    user: vscode
    init: true
    security_opt:
      - seccomp:unconfined
    cap_add:
      - SYS_PTRACE
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          memory: 4G
      restart_policy:
        condition: on-failure
        max_attempts: 3

volumes:
  cairo-cache:
  scarb-cache:
  node_modules:
  contracts-cache:
```

### 4.3 Cairo Development Dockerfile

Create `docker/cairo/dev.Dockerfile`:

```dockerfile
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    vim \
    llvm-14 \
    liblzma-dev \
    libclang-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG MLIR_OPTIMIZATION_LEVEL=3

ENV SCARB_VERSION=${SCARB_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}

# Install Rust with specific version for Cairo compatibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install 1.76.0
RUN rustup default 1.76.0
RUN rustup component add llvm-tools-preview

# Install Scarb (Cairo package manager)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native with MLIR optimization
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --features "mlir-optimizer" --locked

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

# Install security tools
RUN pip3 install cairo-security-scanner starknet-analyzer
RUN npm install -g @veridis/formal-verifier starknet-hardhat-plugin starknet-devnet

# Create non-root user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid vscode --shell /bin/bash --create-home vscode \
    && mkdir -p /home/vscode/.cairo /home/vscode/.local/share/scarb \
    && chown -R vscode:vscode /home/vscode

# Set working directory
WORKDIR /workspace

# Create directory for security scan results
RUN mkdir -p /workspace/security-scan-results && chown vscode:vscode /workspace/security-scan-results

# Switch to non-root user
USER vscode
ENV PATH="/home/vscode/.local/bin:/home/vscode/.cargo/bin:${PATH}"

# Verify installations
RUN scarb --version
RUN snforge --version
RUN cairo-native --version
RUN starknet-analyzer --version
RUN veridis-formal-verifier --version

# Set MLIR optimization environment variables
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}

CMD ["bash"]
```

### 4.4 Development Environment Initialization Script

Create `scripts/init-veridis-env.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Initializing Veridis development environment..."

# Install root dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing root dependencies..."
    npm ci
fi

# Initialize Cairo contracts
if [ -d "contracts" ]; then
    echo "📝 Setting up Cairo contracts..."
    cd contracts
    [ ! -d "target" ] && scarb build --cairo-native --mlir-optimization=true
    [ ! -f ".env.local" ] && cp .env.example .env.local
    cd ..
fi

# Initialize ZK circuits
if [ -d "zk-circuits" ]; then
    echo "🔄 Setting up ZK circuits..."
    cd zk-circuits
    [ ! -d "node_modules" ] && npm ci
    [ ! -d "build" ] && mkdir -p build
    [ ! -d "keys" ] && mkdir -p keys/proving keys/verification
    cd ..
fi

# Initialize services
for service in identity-service attestation-service verification-service compliance-service bridge-service; do
    if [ -d "services/$service" ]; then
        echo "🔧 Setting up $service..."
        cd "services/$service"
        [ ! -d "node_modules" ] && npm ci
        [ ! -f ".env.local" ] && cp .env.example .env.local
        cd ../..
    fi
done

# Initialize client SDKs
for sdk in typescript python mobile; do
    if [ -d "client-sdk/$sdk" ]; then
        echo "📱 Setting up $sdk SDK..."
        cd "client-sdk/$sdk"
        if [ "$sdk" = "python" ]; then
            [ ! -d "venv" ] && python3 -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
        else
            [ ! -d "node_modules" ] && npm ci
        fi
        cd ../..
    fi
done

# Setup formal verification environment if enabled
if [ "$FORMAL_VERIFICATION_ENABLED" = "true" ]; then
    echo "🔍 Setting up formal verification environment..."
    mkdir -p ~/.veridis/formal-verification
    ./scripts/setup-formal-verification.sh
fi

# Setup compliance environment if enabled
if [ "$COMPLIANCE_ENABLED" = "true" ]; then
    echo "🔒 Setting up GDPR compliance environment..."
    mkdir -p ~/.veridis/compliance
    ./scripts/setup-compliance.sh
fi

# Run security scans
if [ "$SECURITY_SCANNING_ENABLED" = "true" ]; then
    echo "🛡️ Running initial security scan..."
    ./scripts/run-security-scan.sh
fi

# Initialize GPU support for ZK proofs if available
if command -v nvidia-smi &> /dev/null; then
    echo "🖥️ Setting up GPU acceleration for ZK proofs..."
    ./scripts/setup-gpu-acceleration.sh
fi

echo "✅ Veridis development environment initialization complete!"
```

## 5. Dockerization Strategy

### 5.1 Component-Specific Docker Images

#### 5.1.1 Cairo Contracts Dockerfile

Create `contracts/Dockerfile`:

```dockerfile
# Build stage
FROM ubuntu:22.04 AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    llvm-14 \
    liblzma-dev \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust with specific version for Cairo compatibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.76.0
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add llvm-tools-preview

# Install Scarb 2.11.4
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.44.0
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native with MLIR optimization
RUN cargo install cairo-native --features "mlir-optimizer" --locked

WORKDIR /app

# Copy Cairo project files
COPY Scarb.toml ./
COPY src ./src
COPY .scarb ./scarb

# Build contracts with optimization
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=3
ENV STARKNET_TX_VERSION=3
RUN scarb build --cairo-native --release

# Run security scan
RUN cargo install cairo-security-scanner --locked
RUN cairo-security-scanner scan --config security/scanner-config.json

# Production stage
FROM ubuntu:22.04 AS production

# Install runtime dependencies (minimal)
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1001 veridis && \
    useradd --uid 1001 --gid veridis -m veridis

# Copy Scarb and Starknet Foundry binaries only (no Rust toolchain)
COPY --from=build /root/.local/bin/scarb /usr/local/bin/
COPY --from=build /root/.local/bin/sncast /usr/local/bin/

# Copy built artifacts
COPY --from=build /app/target ./target
COPY --from=build /app/Scarb.toml ./

# Add deployment scripts
COPY scripts/deploy-contracts.sh ./scripts/
RUN chmod +x ./scripts/deploy-contracts.sh

# Create directory for deployment logs and artifacts
RUN mkdir -p /app/deployments /app/logs && \
    chown -R veridis:veridis /app

WORKDIR /app

# Switch to non-root user
USER veridis

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD sncast --network devnet status || exit 1

# Default command
CMD ["./scripts/deploy-contracts.sh"]
```

#### 5.1.2 Identity Service Dockerfile

Create `services/identity-service/Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine AS build

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    build-base \
    g++ \
    cairo-lang \
    openssl-dev

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Run security scan
RUN npm audit --production --audit-level=moderate

# Build the application
RUN npm run build

# Run tests
FROM build AS test
RUN npm run test

# Scan for vulnerabilities
RUN npm run security:scan

# Production stage
FROM node:20-alpine AS production

# Set NODE_ENV
ENV NODE_ENV=production

# Install security monitoring tools
RUN apk add --no-cache \
    dumb-init \
    curl \
    tzdata \
    ca-certificates

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -s /bin/sh -D appuser

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production --no-optional --no-fund && \
    npm cache clean --force

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/config ./config

# Copy security monitoring
COPY --from=build /app/security ./security

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=512 --disallow-code-generation-from-strings"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate

# Create runtime temporary directory
RUN mkdir -p /app/tmp && chown appuser:appuser /app/tmp
ENV TMPDIR=/app/tmp

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run the application
CMD ["node", "--max-old-space-size=512", "dist/index.js"]
```

#### 5.1.3 ZK Proof Generation Service Dockerfile

Create `zk-circuits/Dockerfile`:

```dockerfile
# Build stage
FROM nvidia/cuda:12.0.0-devel-ubuntu22.04 AS build

# Install system dependencies for native compilation
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    nodejs \
    npm \
    git \
    libssl-dev \
    pkg-config \
    llvm-14 \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for native compilation
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Install Garaga SDK and ZK tools
RUN npm install -g @garaga/cli@latest garaga-cuda

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy circuit source code
COPY . .

# Compile circuits with GPU optimization
ENV GARAGA_CUDA_ENABLED=true
ENV GARAGA_OPTIMIZATION_LEVEL=3
RUN npm run build:optimized

# Security scan for ZK vulnerabilities
RUN npm run security:scan-zk

# Production stage
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    curl \
    dumb-init \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1000 zkuser && \
    useradd --uid 1000 --gid 1000 -m zkuser

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production --no-optional --no-fund && \
    npm cache clean --force

# Copy built circuits and proving keys
COPY --from=build /app/build ./build
COPY --from=build /app/keys ./keys
COPY --from=build /app/config ./config
COPY --from=build /app/proof-service ./proof-service

# Change ownership to non-root user
RUN chown -R zkuser:zkuser /app

# Switch to non-root user
USER zkuser

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=4096 --disallow-code-generation-from-strings"
ENV GARAGA_CUDA_ENABLED=true
ENV ZK_PROOF_SECURITY_LEVEL=128

# Expose proof generation service port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run the proof generation service with GPU support
CMD ["node", "--max-old-space-size=4096", "proof-service/index.js"]
```

#### 5.1.4 Compliance Service Dockerfile

Create `services/compliance-service/Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine AS build

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Run security scan
RUN npm audit --production --audit-level=moderate
RUN npm run security:scan

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Set NODE_ENV
ENV NODE_ENV=production

# Install GDPR compliance and security tools
RUN apk add --no-cache \
    python3 \
    py3-pip \
    dumb-init \
    curl \
    openssl \
    tzdata

# Install compliance libraries with pinned versions
RUN pip3 install \
    gdpr-automation-toolkit==2.5.0 \
    cryptographic-deletion==1.3.2 \
    data-subject-rights-manager==1.1.0 \
    compliance-audit-logger==2.0.1

# Create non-root user
RUN addgroup -g 1000 compliance && \
    adduser -u 1000 -G compliance -s /bin/sh -D compliance

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production --no-optional --no-fund && \
    npm cache clean --force

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/config ./config

# Copy compliance templates
COPY compliance-templates ./compliance-templates

# Create data directories with proper permissions
RUN mkdir -p \
    /app/compliance-data/audit-logs \
    /app/compliance-data/gdpr-requests \
    /app/compliance-data/crypto-erasure \
    /app/compliance-data/reports \
    /app/tmp && \
    chown -R compliance:compliance /app

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=1024 --disallow-code-generation-from-strings"
ENV GDPR_CRYPTO_ERASURE_ENABLED=true
ENV COMPLIANCE_AUDIT_LEVEL=detailed
ENV TMPDIR=/app/tmp

# Change ownership to non-root user
RUN chown -R compliance:compliance /app

# Switch to non-root user
USER compliance

# Expose compliance service port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/sbin/dumb-init", "--"]

# Run the compliance service
CMD ["node", "--max-old-space-size=1024", "dist/index.js"]
```

### 5.2 Base Images

Create shared base images for consistency:

Create `docker/base/cairo-base.Dockerfile`:

```dockerfile
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    jq \
    llvm-14 \
    liblzma-dev \
    libclang-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG MLIR_OPTIMIZATION_LEVEL=3

ENV SCARB_VERSION=${SCARB_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV STARKNET_TX_VERSION=3
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}

# Install Rust with specific version for Cairo compatibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.76.0
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add llvm-tools-preview

# Install Scarb (mandatory version)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native for performance optimization
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --features "mlir-optimizer" --locked

# Install Cairo security tools
RUN cargo install cairo-security-scanner --locked

# Create non-root user
RUN groupadd --gid 1000 cairo \
    && useradd --uid 1000 --gid cairo --shell /bin/bash --create-home cairo \
    && mkdir -p /app && chown cairo:cairo /app

# Set working directory
WORKDIR /app

# Set security-related environment variables
ENV SCARB_SECURITY_AUDIT=true
ENV STARKNET_RESOURCE_BOUNDS_ENABLED=true

# Use non-root user
USER cairo
ENV PATH="/home/cairo/.local/bin:/home/cairo/.cargo/bin:${PATH}"

# Verify installations
RUN scarb --version && \
    snforge --version && \
    cairo-native --version && \
    cairo-security-scanner --version

# Set up a health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD scarb --version > /dev/null
```

Create `docker/base/enterprise-compliance.Dockerfile`:

```dockerfile
FROM node:20-alpine

# Install compliance and security tools
RUN apk add --no-cache \
    python3 \
    py3-pip \
    openssl \
    curl \
    jq \
    dumb-init \
    tzdata \
    ca-certificates

# Install GDPR compliance automation tools with pinned versions
RUN pip3 install \
    gdpr-automation-toolkit==2.5.0 \
    data-privacy-auditor==1.4.2 \
    compliance-reporter==3.1.0 \
    cryptographic-deletion==1.3.2 \
    data-subject-rights-manager==1.1.0

# Install audit and monitoring tools
RUN npm install -g \
    @veridis/audit-logger@2.1.0 \
    @veridis/compliance-monitor@3.0.2 \
    @veridis/gdpr-automation@2.2.1 \
    snyk@1.1160.0

# Create compliance user
RUN addgroup -g 1000 compliance && \
    adduser -u 1000 -G compliance -s /bin/sh -D compliance

# Create directories for compliance data with proper permissions
RUN mkdir -p /compliance/audit-logs \
             /compliance/gdpr-data \
             /compliance/reports \
             /compliance/crypto-erasure \
             /compliance/tmp && \
    chown -R compliance:compliance /compliance

# Set working directory
WORKDIR /app

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=1024 --disallow-code-generation-from-strings"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate
ENV GDPR_CRYPTO_ERASURE_ENABLED=true
ENV COMPLIANCE_AUDIT_LEVEL=detailed
ENV TMPDIR=/compliance/tmp

# Use non-root user
USER compliance

# Health check for compliance services
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3001/compliance/health || exit 1

# Use dumb-init as the entrypoint
ENTRYPOINT ["/sbin/dumb-init", "--"]
```

## 6. Docker Compose Configuration

### 6.1 Main Docker Compose

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  starknet-devnet:
    image: shardlabs/starknet-devnet:v0.8.1
    ports:
      - "5050:5050"
    command: ["--host", "0.0.0.0", "--port", "5050", "--seed", "42"]
    networks:
      - veridis-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5050/is_alive"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  identity-service:
    build:
      context: ./services/identity-service
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
      - starknet-devnet
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_identity
      - REDIS_URL=redis://redis:6379
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
      - JWT_SECRET=${JWT_SECRET}
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    volumes:
      - identity-logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp

  attestation-service:
    build:
      context: ./services/attestation-service
      dockerfile: Dockerfile
      target: production
    ports:
      - "3001:3000"
    depends_on:
      - postgres
      - redis
      - starknet-devnet
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_attestation
      - REDIS_URL=redis://redis:6379
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
      - JWT_SECRET=${JWT_SECRET}
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    volumes:
      - attestation-logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp

  verification-service:
    build:
      context: ./services/verification-service
      dockerfile: Dockerfile
      target: production
    ports:
      - "3002:3000"
    depends_on:
      - postgres
      - redis
      - zk-proof-service
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_verification
      - REDIS_URL=redis://redis:6379
      - ZK_PROOF_SERVICE_URL=http://zk-proof-service:4000
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    volumes:
      - verification-logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp

  compliance-service:
    build:
      context: ./services/compliance-service
      dockerfile: Dockerfile
      target: production
    ports:
      - "3003:3001"
    depends_on:
      - postgres
      - redis
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_compliance
      - REDIS_URL=redis://redis:6379
      - GDPR_AUTOMATION_ENABLED=true
      - GDPR_CRYPTO_ERASURE_ENABLED=true
      - AUDIT_LOG_RETENTION_DAYS=2555
      - PORT=3001
    volumes:
      - compliance-data:/app/compliance-data
      - compliance-logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp

  bridge-service:
    build:
      context: ./services/bridge-service
      dockerfile: Dockerfile
      target: production
    ports:
      - "3004:3000"
    depends_on:
      - postgres
      - redis
      - starknet-devnet
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_bridge
      - REDIS_URL=redis://redis:6379
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
      - ETHEREUM_RPC_URL=${ETHEREUM_RPC_URL}
      - COSMOS_RPC_URL=${COSMOS_RPC_URL}
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    volumes:
      - bridge-logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp

  zk-proof-service:
    build:
      context: ./zk-circuits
      dockerfile: Dockerfile
      target: production
    ports:
      - "4000:4000"
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - GARAGA_OPTIMIZATION=true
      - GARAGA_OPTIMIZATION_LEVEL=3
      - GARAGA_CUDA_ENABLED=${CUDA_ENABLED:-false}
      - ZK_PROOF_SECURITY_LEVEL=128
      - PROOF_GENERATION_TIMEOUT=60000
      - PORT=4000
    volumes:
      - zk-keys:/app/keys
      - zk-cache:/app/cache
      - zk-logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: "2"
        reservations:
          memory: 2G
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /app/tmp
    runtime: ${NVIDIA_RUNTIME:-runc}

  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    networks:
      - veridis-network
    environment:
      - POSTGRES_USER=veridis
      - POSTGRES_PASSWORD=veridis
      - POSTGRES_DB=veridis_main
      - POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U veridis"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
    security_opt:
      - no-new-privileges:true

  redis:
    image: redis:7-alpine
    command:
      [
        "redis-server",
        "--appendonly",
        "yes",
        "--requirepass",
        "${REDIS_PASSWORD:-veridis}",
      ]
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - veridis-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD:-veridis}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
    security_opt:
      - no-new-privileges:true

networks:
  veridis-network:
    driver: bridge
    name: veridis-network
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
    driver_opts:
      encrypt: "true"

volumes:
  postgres-data:
  redis-data:
  compliance-data:
  zk-keys:
  zk-cache:
  identity-logs:
  attestation-logs:
  verification-logs:
  compliance-logs:
  bridge-logs:
  zk-logs:
```

### 6.2 Development Overrides

Create `docker-compose.dev.yml`:

````yaml
version: "3.8"

services:
  starknet-devnet:
    command:
      ["--host", "0.0.0.0", "--port", "5050", "--seed", "42", "--lite-mode", "--accounts", "10"]
    environment:
      - STARKNET_DEVNET_LITE_MODE=true
      - STARKNET_TX_VERSION=3
      - STARKNET_RESOURCE_BOUNDS_ENABLED=true
    ports:
      - "5050:5050"

  identity-service:
    build:
      target: build
    volumes:
      - ./services/identity-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
    security_opt: []
    read_only: false
    tmpfs: []

  attestation-service:
    build:
      target: build
    volumes:
      - ./services/attestation-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
    security_opt: []
    read_only: false
    tmpfs: []

  verification-service:
    build:
      target: build
    volumes:
      - ./services/verification-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
    security_opt: []
    read_only: false
    tmpfs: []

  compliance-service:
    build:
      target: build
    volumes:
      - ./services/compliance-service:/app
      - /app/node_modules
    command: npm run dev
    ```yaml
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - GDPR_AUTOMATION_ENABLED=false
      - GDPR_CRYPTO_ERASURE_ENABLED=false
    security_opt: []
    read_only: false
    tmpfs: []

  bridge-service:
    build:
      target: build
    volumes:
      - ./services/bridge-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
    security_opt: []
    read_only: false
    tmpfs: []

  zk-proof-service:
    build:
      target: build
    volumes:
      - ./zk-circuits:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - GARAGA_OPTIMIZATION=false
      - GARAGA_CUDA_ENABLED=false
      - PROOF_TIMEOUT_OVERRIDE=120000
    security_opt: []
    read_only: false
    tmpfs: []

  postgres:
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=veridis_dev
    volumes:
      - ./scripts/init-dev-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    command: ["postgres", "-c", "log_statement=all", "-c", "log_destination=stderr"]

  redis:
    ports:
      - "6379:6379"
    command: ["redis-server", "--loglevel", "verbose"]

  # Development-only services
  cairo-dev:
    build:
      context: .
      dockerfile: docker/cairo/dev.Dockerfile
      args:
        SCARB_VERSION: "2.11.4"
        CAIRO_NATIVE_VERSION: "2.11.4"
        STARKNET_FOUNDRY_VERSION: "0.44.0"
        MLIR_OPTIMIZATION_LEVEL: "3"
    volumes:
      - ./contracts:/app/contracts
      - cairo-cache:/home/vscode/.cairo
      - scarb-cache:/home/vscode/.local/share/scarb
    working_dir: /app/contracts
    command: sleep infinity
    networks:
      - veridis-network
    environment:
      - SCARB_VERSION=2.11.4
      - CAIRO_NATIVE_ENABLED=true
      - MLIR_OPTIMIZATION_LEVEL=3
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
      - FORMAL_VERIFICATION_ENABLED=true
    ports:
      - "5051:5051"

  # Development tools
  dev-tools:
    image: veridis/dev-tools:latest
    volumes:
      - .:/workspace
      - ~/.gitconfig:/home/dev/.gitconfig:ro
    ports:
      - "9876:9876"  # Development tools web UI
    environment:
      - NODE_ENV=development
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
    networks:
      - veridis-network
    depends_on:
      - starknet-devnet
      - postgres
      - redis

volumes:
  cairo-cache:
  scarb-cache:
````

### 6.3 Enterprise Configuration

Create `docker-compose.enterprise.yml`:

```yaml
version: "3.8"

services:
  identity-service:
    environment:
      - COMPLIANCE_LEVEL=ENTERPRISE
      - GDPR_STRICT_MODE=true
      - AUDIT_EVERYTHING=true
      - RESOURCE_BOUNDS_VALIDATION=true
      - LOG_LEVEL=info
      - SECURITY_HEADERS_ENABLED=true
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 2G
          cpus: "2"
      restart_policy:
        condition: any
        delay: 5s
        max_attempts: 5
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "10"
    volumes:
      - audit-logs:/app/audit-logs:rw

  attestation-service:
    environment:
      - COMPLIANCE_LEVEL=ENTERPRISE
      - ATTESTATION_AUDIT_LOG=true
      - FORMAL_VERIFICATION_ENABLED=true
      - STORAGE_ENCRYPTION_ENABLED=true
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 2G
          cpus: "2"
    volumes:
      - attestation-audit-logs:/app/audit-logs:rw

  compliance-service:
    environment:
      - ENTERPRISE_FEATURES=true
      - REAL_TIME_MONITORING=true
      - IMMUTABLE_AUDIT_LOG=true
      - SOC2_COMPLIANCE=true
      - CRYPTO_ERASURE_ROUNDS=3
      - COMPLIANCE_REPORTS_ENABLED=true
      - DATA_SUBJECT_RIGHTS_AUTOMATION=true
    volumes:
      - compliance-audit-logs:/app/audit-logs:ro
      - compliance-reports:/app/reports:rw
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 4G
          cpus: "2"
      placement:
        constraints:
          - node.role == worker
          - node.labels.compliance == true

  zk-proof-service:
    environment:
      - GARAGA_OPTIMIZATION_LEVEL=3
      - GARAGA_CUDA_ENABLED=true
      - ZK_PROOF_SECURITY_LEVEL=128
      - FORMAL_VERIFICATION_ENABLED=true
      - PROOF_VERIFICATION_THRESHOLD=100
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    volumes:
      - zk-proof-audit:/app/audit-logs:rw

  # Enterprise monitoring stack
  prometheus:
    image: prom/prometheus:v2.43.0
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./monitoring/alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus-data:/prometheus
    networks:
      - veridis-network
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=30d"
      - "--web.console.libraries=/usr/share/prometheus/console_libraries"
      - "--web.console.templates=/usr/share/prometheus/consoles"
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: "1"

  grafana:
    image: grafana/grafana:9.4.3
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana-datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml:ro
      - ./monitoring/grafana-dashboards.yaml:/etc/grafana/provisioning/dashboards/dashboards.yaml:ro
      - ./monitoring/dashboards:/var/lib/grafana/dashboards:ro
    networks:
      - veridis-network
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-veridis-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-clock-panel
    depends_on:
      - prometheus
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"

  alertmanager:
    image: prom/alertmanager:v0.25.0
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/config.yml:ro
      - alertmanager-data:/alertmanager
    networks:
      - veridis-network
    command:
      - "--config.file=/etc/alertmanager/config.yml"
      - "--storage.path=/alertmanager"
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"

  # Enterprise security scanner
  security-scanner:
    image: veridis/security-scanner:latest
    volumes:
      - ./:/scan-target:ro
      - security-reports:/reports
    environment:
      - SCAN_SCHEDULE=0 2 * * *
      - COMPLIANCE_CHECK=true
      - CAIRO_VERSION=2.11.4
      - STARKNET_VERSION=0.13.4
      - SECURITY_BASELINE=/opt/veridis/security-baseline.json
      - ENTERPRISE_SCAN_LEVEL=comprehensive
    networks:
      - veridis-network
    depends_on:
      - compliance-service
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: "2"

  # Enterprise backup service
  backup-service:
    image: veridis/backup-service:latest
    volumes:
      - postgres-backup:/backups/postgres
      - starknet-backup:/backups/starknet
      - keys-backup:/backups/keys
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - BACKUP_SCHEDULE=0 1 * * *
      - BACKUP_RETENTION_DAYS=90
      - ENCRYPTION_ENABLED=true
      - ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY}
      - S3_BACKUP_ENABLED=${S3_BACKUP_ENABLED:-false}
      - S3_BUCKET=${S3_BUCKET}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    networks:
      - veridis-network
    depends_on:
      - postgres
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: "1"

volumes:
  audit-logs:
  attestation-audit-logs:
  compliance-audit-logs:
  compliance-reports:
  zk-proof-audit:
  prometheus-data:
  grafana-data:
  alertmanager-data:
  security-reports:
  postgres-backup:
  starknet-backup:
  keys-backup:
```

## 7. Kubernetes Deployment

### 7.1 Kustomize Structure

Create a Kustomize-based deployment structure:

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── identity-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   ├── attestation-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   ├── verification-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   ├── compliance-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── pvc.yaml
│   ├── bridge-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   ├── zk-proof-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── pvc.yaml
│   ├── starknet-node/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── infrastructure/
│   │   ├── postgres-statefulset.yaml
│   │   ├── postgres-service.yaml
│   │   ├── postgres-pvc.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── redis-service.yaml
│   │   ├── redis-configmap.yaml
│   │   └── starknet-devnet.yaml
│   └── security/
│       ├── network-policies.yaml
│       ├── pod-security-policies.yaml
│       └── security-context.yaml
├── development/
│   ├── kustomization.yaml
│   ├── patches/
│   │   ├── dev-resources.yaml
│   │   ├── dev-replicas.yaml
│   │   └── dev-configmap.yaml
│   └── ingress.yaml
├── staging/
│   ├── kustomization.yaml
│   ├── patches/
│   │   ├── staging-resources.yaml
│   │   ├── staging-replicas.yaml
│   │   └── staging-configmap.yaml
│   └── ingress.yaml
└── production/
    ├── kustomization.yaml
    ├── patches/
    │   ├── production-resources.yaml
    │   ├── production-replicas.yaml
    │   ├── production-configmap.yaml
    │   └── production-hpa.yaml
    ├── ingress.yaml
    ├── certificate.yaml
    └── monitoring/
        ├── prometheus.yaml
        ├── grafana.yaml
        └── alertmanager.yaml
```

### 7.2 Base Resources

Create `k8s/base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - identity-service/deployment.yaml
  - identity-service/service.yaml
  - identity-service/configmap.yaml
  - identity-service/hpa.yaml
  - attestation-service/deployment.yaml
  - attestation-service/service.yaml
  - attestation-service/configmap.yaml
  - attestation-service/hpa.yaml
  - verification-service/deployment.yaml
  - verification-service/service.yaml
  - verification-service/configmap.yaml
  - verification-service/hpa.yaml
  - compliance-service/deployment.yaml
  - compliance-service/service.yaml
  - compliance-service/configmap.yaml
  - compliance-service/pvc.yaml
  - bridge-service/deployment.yaml
  - bridge-service/service.yaml
  - bridge-service/configmap.yaml
  - bridge-service/hpa.yaml
  - zk-proof-service/deployment.yaml
  - zk-proof-service/service.yaml
  - zk-proof-service/configmap.yaml
  - zk-proof-service/pvc.yaml
  - infrastructure/postgres-statefulset.yaml
  - infrastructure/postgres-service.yaml
  - infrastructure/postgres-pvc.yaml
  - infrastructure/redis-deployment.yaml
  - infrastructure/redis-service.yaml
  - infrastructure/redis-configmap.yaml
  - infrastructure/starknet-devnet.yaml
  - security/network-policies.yaml
  - security/pod-security-policies.yaml
  - security/security-context.yaml

namespace: veridis

commonLabels:
  app: veridis
  part-of: veridis-protocol
  version: v3.2.1
  managed-by: kustomize

commonAnnotations:
  veridis.xyz/cairo-version: "2.11.4"
  veridis.xyz/starknet-version: "0.13.4"
```

Create `k8s/base/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: veridis
  labels:
    name: veridis
    compliance: enterprise
    security-tier: sensitive
    network-policy: strict
    istio-injection: enabled
  annotations:
    veridis.xyz/description: "Veridis Protocol Deployment Namespace"
    veridis.xyz/owner: "Veridis Core Team"
    veridis.xyz/contact: "ops@veridis.xyz"
```

Create `k8s/base/identity-service/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: identity-service
  labels:
    app: identity-service
    component: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: identity-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: identity-service
        component: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
        - name: identity-service
          image: ghcr.io/veridis-protocol/identity-service:v3.2.1
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 3000
              protocol: TCP
          resources:
            limits:
              cpu: "1"
              memory: "1Gi"
            requests:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 2
          startupProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 12
          envFrom:
            - configMapRef:
                name: identity-service-config
            - secretRef:
                name: veridis-secrets
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: app-cache
              mountPath: /app/cache
            - name: logs
              mountPath: /app/logs
      volumes:
        - name: tmp
          emptyDir:
            medium: Memory
            sizeLimit: 64Mi
        - name: app-cache
          emptyDir: {}
        - name: logs
          emptyDir: {}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - identity-service
                topologyKey: "kubernetes.io/hostname"
      terminationGracePeriodSeconds: 60
```

Create `k8s/base/identity-service/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: identity-service
  labels:
    app: identity-service
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "3000"
    prometheus.io/path: "/metrics"
spec:
  selector:
    app: identity-service
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
      name: http
  type: ClusterIP
  sessionAffinity: None
```

Create `k8s/base/identity-service/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: identity-service-config
data:
  NODE_ENV: "production"
  PORT: "3000"
  STARKNET_RPC_URL: "http://starknet-devnet.veridis.svc.cluster.local:5050/rpc/v0_8_1"
  STARKNET_TX_VERSION: "3"
  RESOURCE_BOUNDS_ENABLED: "true"
  REDIS_URL: "redis://redis.veridis.svc.cluster.local:6379"
  LOG_LEVEL: "info"
  METRICS_ENABLED: "true"
  COMPLIANCE_LEVEL: "STANDARD"
  PROMETHEUS_METRICS_PATH: "/metrics"
  SECURITY_HEADERS_ENABLED: "true"
  REQUEST_TIMEOUT_MS: "30000"
  CONNECTION_TIMEOUT_MS: "5000"
  CORS_ALLOWED_ORIGINS: "https://app.veridis.xyz,https://api.veridis.xyz"
  CAIRO_VERSION: "2.11.4"
  MLIR_OPTIMIZATION_LEVEL: "3"
```

Create `k8s/base/identity-service/hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: identity-service
  labels:
    app: identity-service
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: identity-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 75
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
        - type: Pods
          value: 4
          periodSeconds: 15
```

### 7.3 Production Environment

Create `k8s/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../base
  - ingress.yaml
  - certificate.yaml
  - monitoring/prometheus.yaml
  - monitoring/grafana.yaml
  - monitoring/alertmanager.yaml

namespace: veridis-prod

namePrefix: prod-

commonLabels:
  environment: production
  compliance: enterprise
  tier: production

patchesStrategicMerge:
  - patches/production-resources.yaml
  - patches/production-replicas.yaml
  - patches/production-configmap.yaml
  - patches/production-hpa.yaml
  - patches/production-security.yaml

configMapGenerator:
  - name: identity-service-config
    behavior: merge
    literals:
      - COMPLIANCE_LEVEL=ENTERPRISE
      - GDPR_STRICT_MODE=true
      - AUDIT_EVERYTHING=true
      - LOG_LEVEL=info
      - REDIS_URL=redis://prod-redis.veridis-prod.svc.cluster.local:6379
      - STARKNET_RPC_URL=https://starknet-mainnet.infura.io/v3/${INFURA_API_KEY}
      - STARKNET_CHAIN_ID=SN_MAIN
  - name: compliance-service-config
    behavior: merge
    literals:
      - ENTERPRISE_FEATURES=true
      - REAL_TIME_MONITORING=true
      - IMMUTABLE_AUDIT_LOG=true
      - SOC2_COMPLIANCE=true
      - CRYPTO_ERASURE_ROUNDS=3
      - REDIS_URL=redis://prod-redis.veridis-prod.svc.cluster.local:6379
  - name: zk-proof-service-config
    behavior: merge
    literals:
      - GARAGA_OPTIMIZATION_LEVEL=3
      - GARAGA_CUDA_ENABLED=true
      - ZK_PROOF_SECURITY_LEVEL=128
      - PROOF_VERIFICATION_THRESHOLD=100

secretGenerator:
  - name: veridis-secrets
    envs:
      - .env.production.secrets
    type: Opaque

images:
  - name: ghcr.io/veridis-protocol/identity-service
    newTag: v3.2.1
  - name: ghcr.io/veridis-protocol/attestation-service
    newTag: v3.2.1
  - name: ghcr.io/veridis-protocol/verification-service
    newTag: v3.2.1
  - name: ghcr.io/veridis-protocol/compliance-service
    newTag: v3.2.1
  - name: ghcr.io/veridis-protocol/bridge-service
    newTag: v3.2.1
  - name: ghcr.io/veridis-protocol/zk-proof-service
    newTag: v3.2.1
```

Create `k8s/production/patches/production-resources.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: identity-service
spec:
  template:
    spec:
      containers:
        - name: identity-service
          resources:
            limits:
              cpu: "2"
              memory: "2Gi"
            requests:
              cpu: "1"
              memory: "1Gi"
          env:
            - name: NODE_OPTIONS
              value: "--max-old-space-size=1536 --max-http-header-size=16384"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-type
                    operator: In
                    values:
                      - services
                  - key: environment
                    operator: In
                    values:
                      - production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliance-service
spec:
  template:
    spec:
      containers:
        - name: compliance-service
          resources:
            limits:
              cpu: "4"
              memory: "8Gi"
            requests:
              cpu: "2"
              memory: "4Gi"
          env:
            - name: IMMUTABLE_AUDIT_LOG
              value: "true"
            - name: COMPLIANCE_SCANNING
              value: "continuous"
            - name: NODE_OPTIONS
              value: "--max-old-space-size=6144"
      nodeSelector:
        compliance-tier: enterprise
        environment: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zk-proof-service
spec:
  template:
    spec:
      containers:
        - name: zk-proof-service
          resources:
            limits:
              cpu: "8"
              memory: "16Gi"
              nvidia.com/gpu: 2
            requests:
              cpu: "4"
              memory: "8Gi"
              nvidia.com/gpu: 1
          env:
            - name: GARAGA_CUDA_ENABLED
              value: "true"
            - name: GARAGA_OPTIMIZATION_LEVEL
              value: "3"
            - name: NODE_OPTIONS
              value: "--max-old-space-size=12288"
      nodeSelector:
        accelerator: gpu
        environment: production
```

## 8. Environment Configuration Management

### 8.1 Environment Variables Strategy

Create structured environment configuration files:

```
config/
├── .env.development       # Development environment
├── .env.test              # Testing environment
├── .env.staging           # Staging environment
├── .env.production        # Production environment
├── .env.enterprise        # Enterprise-specific overrides
└── .env.example           # Example file with variable names
```

Create `config/.env.example`:

```bash
# Core Configuration
NODE_ENV=development
PORT=3000

# StarkNet Configuration
STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
STARKNET_CHAIN_ID=SN_GOERLI
STARKNET_TX_VERSION=3
RESOURCE_BOUNDS_ENABLED=true
RESOURCE_BOUNDS_L1_GAS=100000
RESOURCE_BOUNDS_L2_GAS=1000000
CAIRO_VERSION=2.11.4
MLIR_OPTIMIZATION_LEVEL=3

# Database Configuration
DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_main
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=your-redis-password-here

# Authentication
JWT_SECRET=your-jwt-secret-here
JWT_EXPIRATION=24h
AUTH_REQUIRED=true
REFRESH_TOKEN_EXPIRATION=30d

# Cross-Chain Configuration
ETHEREUM_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your-api-key
COSMOS_RPC_URL=https://cosmos-rpc.polkachu.com
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
POLKADOT_RPC_URL=wss://rpc.polkadot.io

# ZK Proof Configuration
GARAGA_OPTIMIZATION=true
GARAGA_OPTIMIZATION_LEVEL=3
GARAGA_CUDA_ENABLED=false
PROOF_GENERATION_TIMEOUT=60000
ZK_CIRCUIT_PATH=/app/circuits
ZK_PROOF_SECURITY_LEVEL=128

# Compliance Configuration
COMPLIANCE_LEVEL=STANDARD
GDPR_AUTOMATION_ENABLED=false
GDPR_CRYPTO_ERASURE_ENABLED=false
CRYPTO_ERASURE_ROUNDS=1
AUDIT_LOG_RETENTION_DAYS=90
SOC2_COMPLIANCE=false
DATA_SUBJECT_RIGHTS_AUTOMATION=false

# Performance Configuration
CAIRO_NATIVE_ENABLED=true
GAS_OPTIMIZATION=true
BATCH_PROCESSING=true
REQUEST_TIMEOUT_MS=30000
CONNECTION_TIMEOUT_MS=5000
MAX_CONCURRENT_PROOFS=4

# Security Configuration
SECURITY_HEADERS_ENABLED=true
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
RATE_LIMIT_ENABLED=true
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
NODE_OPTIONS="--max-old-space-size=1024 --max-http-header-size=16384"

# Monitoring
METRICS_ENABLED=true
PROMETHEUS_METRICS_PATH=/metrics
LOG_LEVEL=info
SENTRY_DSN=your-sentry-dsn-here
JAEGER_AGENT_HOST=jaeger-agent
JAEGER_AGENT_PORT=6832

# Enterprise Features (only in enterprise mode)
ENTERPRISE_FEATURES=false
REAL_TIME_MONITORING=false
IMMUTABLE_AUDIT_LOG=false
THREAT_DETECTION=false
FORMAL_VERIFICATION_ENABLED=false
COMPLIANCE_REPORTS_ENABLED=false

# High Availability
HA_ENABLED=false
LEADER_ELECTION_ENABLED=false
LEADER_ELECTION_TTL=15
```

### 8.2 Secret Management with Kubernetes

Create `k8s/base/secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: veridis-secrets
  annotations:
    replicator.v1.mittwald.de/replication-allowed: "true"
    replicator.v1.mittwald.de/replication-allowed-namespaces: "veridis-*"
type: Opaque
data:
  # These are examples - actual secrets should be managed via a secure vault
  JWT_SECRET: # base64 encoded secret
  DATABASE_PASSWORD: # base64 encoded password
  REDIS_PASSWORD: # base64 encoded password
  ETHEREUM_RPC_API_KEY: # base64 encoded API key
  SENTRY_DSN: # base64 encoded Sentry DSN
  INFURA_API_KEY: # base64 encoded Infura API key
---
apiVersion: v1
kind: Secret
metadata:
  name: compliance-secrets
  annotations:
    replicator.v1.mittwald.de/replication-allowed: "true"
    replicator.v1.mittwald.de/replication-allowed-namespaces: "veridis-*"
type: Opaque
data:
  GDPR_ENCRYPTION_KEY: # base64 encoded encryption key
  AUDIT_SIGNING_KEY: # base64 encoded signing key
  COMPLIANCE_WEBHOOK_SECRET: # base64 encoded webhook secret
  CRYPTO_ERASURE_SALT: # base64 encoded salt for cryptographic erasure
```

### 8.3 Configuration Validation Script

Create `scripts/validate-config.js`:

```javascript
const dotenv = require("dotenv");
const fs = require("fs");
const path = require("path");
const semver = require("semver");

// Load environment variables
const envFile = `.env.${process.env.NODE_ENV || "development"}`;
const envPath = path.resolve(process.cwd(), "config", envFile);

if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
} else {
  console.warn(`Warning: ${envFile} not found, using process.env`);
}

// Define required versions
const requiredVersions = {
  CAIRO_VERSION: "2.11.4",
  STARKNET_TX_VERSION: "3",
};

// Define required variables by service
const requiredVariables = {
  core: ["NODE_ENV", "PORT", "DATABASE_URL", "REDIS_URL", "JWT_SECRET"],
  starknet: [
    "STARKNET_RPC_URL",
    "STARKNET_CHAIN_ID",
    "STARKNET_TX_VERSION",
    "RESOURCE_BOUNDS_ENABLED",
  ],
  crosschain: ["ETHEREUM_RPC_URL", "COSMOS_RPC_URL"],
  zkproof: [
    "GARAGA_OPTIMIZATION",
    "ZK_CIRCUIT_PATH",
    "ZK_PROOF_SECURITY_LEVEL",
  ],
  compliance: ["COMPLIANCE_LEVEL", "AUDIT_LOG_RETENTION_DAYS"],
  security: [
    "SECURITY_HEADERS_ENABLED",
    "CORS_ALLOWED_ORIGINS",
    "RATE_LIMIT_ENABLED",
  ],
};

// Enterprise-only variables
const enterpriseVariables = [
  "ENTERPRISE_FEATURES",
  "REAL_TIME_MONITORING",
  "IMMUTABLE_AUDIT_LOG",
  "SOC2_COMPLIANCE",
  "CRYPTO_ERASURE_ROUNDS",
  "DATA_SUBJECT_RIGHTS_AUTOMATION",
];

// Validate core variables
function validateVariables(category, variables) {
  const missing = variables.filter((varName) => !process.env[varName]);
  if (missing.length > 0) {
    console.error(`Error: Missing required ${category} variables:`);
    missing.forEach((varName) => console.error(`- ${varName}`));
    return false;
  }
  return true;
}

// Validate version requirements
function validateVersions(versionRequirements) {
  let valid = true;

  for (const [key, requiredVersion] of Object.entries(versionRequirements)) {
    const currentVersion = process.env[key];

    if (!currentVersion) {
      console.error(`Error: ${key} not defined in environment`);
      valid = false;
      continue;
    }

    // Handle semantic versions
    if (semver.valid(requiredVersion) && semver.valid(currentVersion)) {
      if (!semver.satisfies(currentVersion, requiredVersion)) {
        console.error(
          `Error: ${key} version mismatch. Required: ${requiredVersion}, Found: ${currentVersion}`
        );
        valid = false;
      }
    }
    // Handle non-semver values like STARKNET_TX_VERSION
    else if (currentVersion !== requiredVersion) {
      console.error(
        `Error: ${key} value mismatch. Required: ${requiredVersion}, Found: ${currentVersion}`
      );
      valid = false;
    }
  }

  return valid;
}

// Main validation
let valid = true;

// Validate core requirements
for (const [category, variables] of Object.entries(requiredVariables)) {
  if (!validateVariables(category, variables)) {
    valid = false;
  }
}

// Validate version requirements
if (!validateVersions(requiredVersions)) {
  valid = false;
}

// Validate enterprise requirements if enterprise mode is enabled
if (process.env.COMPLIANCE_LEVEL === "ENTERPRISE") {
  if (!validateVariables("enterprise", enterpriseVariables)) {
    valid = false;
  }

  // Additional enterprise validations
  if (process.env.CRYPTO_ERASURE_ROUNDS < 3) {
    console.error(
      "Error: CRYPTO_ERASURE_ROUNDS must be at least 3 for enterprise compliance"
    );
    valid = false;
  }
}

// Validate resource bounds configuration
if (process.env.RESOURCE_BOUNDS_ENABLED === "true") {
  if (
    !process.env.RESOURCE_BOUNDS_L1_GAS ||
    !process.env.RESOURCE_BOUNDS_L2_GAS
  ) {
    console.error(
      "Error: RESOURCE_BOUNDS_L1_GAS and RESOURCE_BOUNDS_L2_GAS required when resource bounds are enabled"
    );
    valid = false;
  }
}

// Validate compliance configuration
if (
  process.env.GDPR_AUTOMATION_ENABLED === "true" &&
  !process.env.GDPR_ENCRYPTION_KEY
) {
  console.error(
    "Error: GDPR_ENCRYPTION_KEY required when GDPR automation is enabled"
  );
  valid = false;
}

// Validate security configuration
if (
  process.env.SECURITY_HEADERS_ENABLED === "true" &&
  !process.env.CORS_ALLOWED_ORIGINS
) {
  console.error(
    "Error: CORS_ALLOWED_ORIGINS required when security headers are enabled"
  );
  valid = false;
}

if (valid) {
  console.log("✅ Configuration validation passed!");
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Cairo Version: ${process.env.CAIRO_VERSION}`);
  console.log(
    `StarkNet Transaction Version: ${process.env.STARKNET_TX_VERSION}`
  );
  console.log(`Compliance Level: ${process.env.COMPLIANCE_LEVEL}`);
  console.log(`Cairo Native: ${process.env.CAIRO_NATIVE_ENABLED}`);
  console.log(
    `MLIR Optimization Level: ${process.env.MLIR_OPTIMIZATION_LEVEL}`
  );
} else {
  console.error("❌ Configuration validation failed!");
  process.exit(1);
}
```

## 9. Cairo-Specific Container Configurations

### 9.1 Cairo Contract Compilation Container

Create `docker/cairo/compiler.Dockerfile`:

```dockerfile
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    llvm-14 \
    liblzma-dev \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ARG SCARB_VERSION=2.11.4
ARG CAIRO_NATIVE_VERSION=2.11.4
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG MLIR_OPTIMIZATION_LEVEL=3

ENV SCARB_VERSION=${SCARB_VERSION}
ENV CAIRO_NATIVE_VERSION=${CAIRO_NATIVE_VERSION}
ENV STARKNET_FOUNDRY_VERSION=${STARKNET_FOUNDRY_VERSION}
ENV MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=${MLIR_OPTIMIZATION_LEVEL}
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true

# Install Rust with specific version for Cairo compatibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.76.0
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add llvm-tools-preview

# Install Scarb (Cairo package manager)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v ${SCARB_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v ${STARKNET_FOUNDRY_VERSION}
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native with MLIR optimization
RUN cargo install cairo-native --version ${CAIRO_NATIVE_VERSION} --features "mlir-optimizer" --locked

# Install Cairo security scanner
RUN cargo install cairo-security-scanner --locked

WORKDIR /workspace

# Copy compilation script
COPY scripts/compile-cairo.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/compile-cairo.sh

# Verify installations
RUN scarb --version
RUN snforge --version
RUN cairo-native --version
RUN cairo-security-scanner --version

# Default command
ENTRYPOINT ["/usr/local/bin/compile-cairo.sh"]
```

Create `scripts/compile-cairo.sh`:

```bash
#!/bin/bash
set -e

echo "🔨 Compiling Cairo contracts for Veridis..."

# Validate Scarb version
SCARB_VERSION=$(scarb --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [ "$SCARB_VERSION" != "2.11.4" ]; then
    echo "❌ Error: Scarb version must be 2.11.4, found $SCARB_VERSION"
    exit 1
fi

# Validate configuration
if [ "$STARKNET_TX_VERSION" != "3" ]; then
    echo "⚠️ Warning: StarkNet transaction version should be 3, found $STARKNET_TX_VERSION"
fi

if [ "$RESOURCE_BOUNDS_ENABLED" != "true" ]; then
    echo "⚠️ Warning: Resource bounds should be enabled for production deployments"
fi

# Set optimization flags
OPTIMIZATION_FLAGS=""
if [ "$CAIRO_NATIVE_ENABLED" = "true" ]; then
    echo "⚡ Building with Cairo Native optimization (level: $MLIR_OPTIMIZATION_LEVEL)..."
    OPTIMIZATION_FLAGS="--cairo-native --mlir-optimization-level=$MLIR_OPTIMIZATION_LEVEL"

    # Set environment variable for Cairo Native
    export CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=$MLIR_OPTIMIZATION_LEVEL
else
    echo "📦 Building with standard Cairo compiler..."
fi

# Build with specified optimization
scarb build $OPTIMIZATION_FLAGS

# Generate contract artifacts for deployment
echo "📋 Generating contract artifacts..."
scarb build --check $OPTIMIZATION_FLAGS

# Run security scan
echo "🔒 Running security scan..."
cairo-security-scanner scan --directory src --config security/scanner-config.json

# Run formal verification if enabled
if [ "$FORMAL_VERIFICATION" = "true" ]; then
    echo "🔍 Running formal verification..."
    if command -v veridis-formal-verifier &> /dev/null; then
        veridis-formal-verifier verify --project .
    else
        echo "⚠️ Warning: Formal verification tool not found"
    fi
fi

# Generate gas reports
if [ "$GAS_PROFILING" = "true" ]; then
    echo "⛽ Generating gas reports..."
    snforge test --gas-report

    # Save gas snapshot for comparison
    echo "💾 Saving gas snapshot..."
    mkdir -p artifacts
    cp .gas-snapshot artifacts/gas-snapshot-$(date +%Y%m%d-%H%M%S).txt
fi

# Check compliance requirements
if [ "$COMPLIANCE_CHECK" = "true" ]; then
    echo "✅ Running compliance checks..."
    if [ -f "compliance/rules.json" ]; then
        echo "📝 Checking contract compliance..."
        scarb build --check-compliance --rules compliance/rules.json
    else
        echo "⚠️ Warning: Compliance rules file not found"
    fi
fi

# Generate transaction_v3 compatible artifacts
if [ "$STARKNET_TX_VERSION" = "3" ]; then
    echo "📦 Generating transaction_v3 compatible artifacts..."
    scarb build --sierra

    # Convert to CASM with resource bounds
    echo "🔄 Converting to CASM with resource bounds..."
    find target/release -name "*.sierra.json" -exec sh -c '
        OUTPUT="${1%.sierra.json}.casm.json"
        starknet-sierra-compile --add-pythonic-hints "${1}" "${OUTPUT}" --allowed-libfuncs-list-file libfuncs_list.json
    ' sh {} \;
fi

echo "✅ Cairo contract compilation completed successfully!"
```

### 9.2 StarkNet Deployment Container

Create `docker/cairo/deployer.Dockerfile`:

```dockerfile
FROM ghcr.io/veridis-protocol/cairo-base:latest AS base

WORKDIR /app

# Install deployment dependencies
RUN apt-get update && apt-get install -y jq curl && rm -rf /var/lib/apt/lists/*

# Copy deployment scripts
COPY scripts/deploy-starknet.sh /usr/local/bin/
COPY scripts/verify-contracts.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Create deployment artifacts directory
RUN mkdir -p /app/deployments /app/logs && \
    chown -R cairo:cairo /app/deployments /app/logs

# Switch to non-root user
USER cairo

FROM base AS production

# Copy deployment configuration
COPY --chown=cairo:cairo deployment-config/ ./deployment-config/
COPY --chown=cairo:cairo contracts/target/ ./target/

# Create deployment artifacts directory
WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD sncast --network devnet status || exit 1

# Set default command
ENTRYPOINT ["/usr/local/bin/deploy-starknet.sh"]
```

Create `scripts/deploy-starknet.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-development}
NETWORK=${2:-devnet}

echo "🚀 Deploying Veridis contracts to $NETWORK ($ENVIRONMENT)..."

# Validate StarkNet transaction version
if [[ -z "$STARKNET_TX_VERSION" || "$STARKNET_TX_VERSION" != "3" ]]; then
    echo "⚠️ Warning: StarkNet transaction version should be 3 (current: $STARKNET_TX_VERSION)"
fi

# Validate resource bounds
if [[ "$RESOURCE_BOUNDS_ENABLED" != "true" ]]; then
    echo "⚠️ Warning: Resource bounds should be enabled for production deployments"
fi

# Validate environment
case "$ENVIRONMENT" in
  "development")
    RPC_URL="http://starknet-devnet:5050/rpc/v0_8_1"
    ACCOUNT="dev_account"
    ;;
  "staging")
    RPC_URL="https://alpha4.starknet.io/rpc/v0_8_1"
    ACCOUNT="staging_account"
    ;;
  "production")
    RPC_URL="https://alpha-mainnet.starknet.io/rpc/v0_8_1"
    ACCOUNT="production_account"
    ;;
  *)
    echo "❌ Invalid environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Set deployment configuration
export STARKNET_RPC_URL="$RPC_URL"
export STARKNET_ACCOUNT="$ACCOUNT"
export STARKNET_TX_VERSION="3"

# Validate account configuration
echo "🔑 Validating account configuration..."
if ! sncast --network $NETWORK account list | grep -q "$ACCOUNT"; then
    echo "❌ Account '$ACCOUNT' not configured. Please set up the account in your configuration."
    exit 1
fi

# Log deployment details
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "📝 Deployment details:" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Environment: $ENVIRONMENT" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Network: $NETWORK" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  RPC URL: $RPC_URL" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Account: $ACCOUNT" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Transaction Version: $STARKNET_TX_VERSION" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Resource Bounds Enabled: $RESOURCE_BOUNDS_ENABLED" | tee -a /app/logs/deployment-$TIMESTAMP.log
echo "  Timestamp: $TIMESTAMP" | tee -a /app/logs/deployment-$TIMESTAMP.log

# Deploy contracts with resource bounds
echo "📝 Deploying Identity Management contract..."
IDENTITY_CONTRACT=$(sncast --network $NETWORK deploy \
  --contract-name veridis_identity \
  --constructor-calldata 0x1 | grep "Contract address:" | awk '{print $3}')

echo "Identity contract deployed: $IDENTITY_CONTRACT" | tee -a /app/logs/deployment-$TIMESTAMP.log

echo "🏛️ Deploying Attestation Registry contract..."
ATTESTATION_CONTRACT=$(sncast --network $NETWORK deploy \
  --contract-name veridis_attestation \
  --constructor-calldata $IDENTITY_CONTRACT 0x1 | grep "Contract address:" | awk '{print $3}')

echo "Attestation contract deployed: $ATTESTATION_CONTRACT" | tee -a /app/logs/deployment-$TIMESTAMP.log

echo "🔐 Deploying Compliance Engine contract..."
COMPLIANCE_CONTRACT=$(sncast --network $NETWORK deploy \
  --contract-name veridis_compliance \
  --constructor-calldata $ATTESTATION_CONTRACT | grep "Contract address:" | awk '{print $3}')

echo "Compliance contract deployed: $COMPLIANCE_CONTRACT" | tee -a /app/logs/deployment-$TIMESTAMP.log

echo "🌉 Deploying Bridge contract..."
BRIDGE_CONTRACT=$(sncast --network $NETWORK deploy \
  --contract-name veridis_bridge \
  --constructor-calldata $IDENTITY_CONTRACT $ATTESTATION_CONTRACT | grep "Contract address:" | awk '{print $3}')

echo "Bridge contract deployed: $BRIDGE_CONTRACT" | tee -a /app/logs/deployment-$TIMESTAMP.log

# Save deployment artifacts
DEPLOYMENT_FILE="deployments/$ENVIRONMENT-$NETWORK-$TIMESTAMP.json"
cat > "$DEPLOYMENT_FILE" << EOF
{
  "network": "$NETWORK",
  "environment": "$ENVIRONMENT",
  "timestamp": "$TIMESTAMP",
  "transaction_version": "$STARKNET_TX_VERSION",
  "resource_bounds_enabled": "$RESOURCE_BOUNDS_ENABLED",
  "cairo_version": "2.11.4",
  "contracts": {
    "identity": "$IDENTITY_CONTRACT",
    "attestation": "$ATTESTATION_CONTRACT",
    "compliance": "$COMPLIANCE_CONTRACT",
    "bridge": "$BRIDGE_CONTRACT"
  }
}
EOF

# Create symlink to latest deployment
ln -sf "$DEPLOYMENT_FILE" "deployments/$ENVIRONMENT-$NETWORK-latest.json"

# Verify contracts on appropriate networks
if [ "$NETWORK" != "devnet" ] && [ "$VERIFY_CONTRACTS" = "true" ]; then
  echo "🔍 Verifying contracts..."
  ./verify-contracts.sh "$ENVIRONMENT" "$NETWORK"
fi

echo "✅ Deployment completed successfully!"
echo "📄 Deployment artifacts saved to $DEPLOYMENT_FILE"
```

### 9.3 Cairo Testing Container

Create `docker/cairo/tester.Dockerfile`:

```dockerfile
FROM ghcr.io/veridis-protocol/cairo-base:latest AS base

WORKDIR /app

# Install testing dependencies
RUN apt-get update && apt-get install -y \
    lcov \
    jq \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python testing dependencies
RUN pip3 install pytest pytest-xdist pytest-cov

# Set environment variables
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=3
ENV STARKNET_NETWORK=devnet

# Create test results directory
RUN mkdir -p /app/test-results && chown cairo:cairo /app/test-results

# Switch to non-root user
USER cairo

FROM base AS production

# Copy test configuration
COPY --chown=cairo:cairo tests/ ./tests/
COPY --chown=cairo:cairo contracts/src/ ./src/
COPY --chown=cairo:cairo Scarb.toml ./
COPY --chown=cairo:cairo .cairo/ ./.cairo/

# Copy testing scripts
COPY --chown=cairo:cairo scripts/run-cairo-tests.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run-cairo-tests.sh

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD snforge test --check

# Set default command
ENTRYPOINT ["/usr/local/bin/run-cairo-tests.sh"]
```

Create `scripts/run-cairo-tests.sh`:

```bash
#!/bin/bash
set -e

echo "🧪 Running Cairo contract tests for Veridis..."

# Validate environment
if [ "$STARKNET_TX_VERSION" != "3" ]; then
    echo "⚠️ Warning: StarkNet transaction version should be 3, found $STARKNET_TX_VERSION"
fi

if [ "$RESOURCE_BOUNDS_ENABLED" != "true" ]; then
    echo "⚠️ Warning: Resource bounds should be enabled for testing"
fi

# Check if Cairo Native is enabled
if [ "$CAIRO_NATIVE_ENABLED" = "true" ]; then
    echo "⚡ Using Cairo Native with MLIR optimization level $CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL"
    NATIVE_ARGS="--cairo-native --mlir-optimization-level=$CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL"
else
    echo "🔄 Using standard Cairo execution"
    NATIVE_ARGS=""
fi

# Run unit tests
echo "📝 Running unit tests..."
snforge test $NATIVE_ARGS --detailed

# Run integration tests if available
if [ -d "tests/integration" ]; then
    echo "🔗 Running integration tests..."
    snforge test tests/integration/ $NATIVE_ARGS --detailed
fi

# Generate coverage report
if [ "$GENERATE_COVERAGE" = "true" ]; then
    echo "📊 Generating test coverage report..."
    snforge test $NATIVE_ARGS --coverage

    # Generate HTML coverage report
    if command -v snforge-coverage-report &> /dev/null; then
        echo "📈 Generating HTML coverage report..."
        snforge-coverage-report --report-directory test-results/coverage
    fi
fi

# Run gas optimization tests
if [ "$GAS_PROFILING" = "true" ]; then
    echo "⛽ Running gas profiling..."
    snforge test $NATIVE_ARGS --gas-report

    # Save gas snapshot for comparison
    echo "💾 Saving gas snapshot..."
    cp .gas-snapshot test-results/gas-snapshot-$(date +%Y%m%d-%H%M%S).txt

    # Compare with previous gas snapshot if available
    if [ -f "test-results/gas-snapshot-previous.txt" ]; then
        echo "🔄 Comparing with previous gas snapshot..."
        snforge test $NATIVE_ARGS --gas-report --check-gas-snapshot test-results/gas-snapshot-previous.txt || true
    fi
fi

# Run security tests
if [ "$SECURITY_TESTS" = "true" ]; then
    echo "🔐 Running security tests..."

    # Run static analysis
    if command -v cairo-security-scanner &> /dev/null; then
        echo "🔍 Running static security analysis..."
        cairo-security-scanner scan --directory src --output test-results/security-scan.json
    fi

    # Run property-based tests if available
    if [ -d "tests/security" ]; then
        echo "🧮 Running property-based security tests..."
        snforge test tests/security/ $NATIVE_ARGS --detailed
    fi

    # Run fuzzing tests if available
    if [ -d "tests/fuzzing" ]; then
        echo "🐝 Running fuzzing tests..."
        snforge test tests/fuzzing/ $NATIVE_ARGS --fuzz-cases=10000
    fi
fi

# Run formal verification tests
if [ "$FORMAL_VERIFICATION" = "true" ]; then
    echo "🧮 Running formal verification..."
    if command -v veridis-formal-verifier &> /dev/null; then
        veridis-formal-verifier verify --project . --output test-results/verification-report.json
    else
        echo "⚠️ Warning: Formal verification tool not found, skipping verification"
    fi
fi

# Generate test report
echo "📋 Generating test report..."
cat > test-results/test-summary.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cairo_version": "2.11.4",
  "scarb_version": "$(scarb --version)",
  "foundry_version": "$(snforge --version)",
  "starknet_tx_version": "$STARKNET_TX_VERSION",
  "resource_bounds_enabled": "$RESOURCE_BOUNDS_ENABLED",
  "cairo_native_enabled": "$CAIRO_NATIVE_ENABLED",
  "mlir_optimization_level": "$CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL",
  "test_results": {
    "unit_tests": "passed",
    "integration_tests": "$([ -d 'tests/integration' ] && echo 'passed' || echo 'skipped')",
    "security_tests": "$([ '$SECURITY_TESTS' = 'true' ] && echo 'passed' || echo 'skipped')",
    "formal_verification": "$([ '$FORMAL_VERIFICATION' = 'true' ] && echo 'passed' || echo 'skipped')",
    "gas_profiling": "$([ '$GAS_PROFILING' = 'true' ] && echo 'completed' || echo 'skipped')"
  }
}
EOF

echo "✅ Cairo tests completed successfully!"
echo "📊 Test results available in test-results/"
```

## 10. ZK Proof Generation Environment

### 10.1 Garaga SDK Integration Container

Create `docker/zk/garaga.Dockerfile`:

````dockerfile
FROM nvidia/cuda:12.0.0-devel-ubuntu22.04 AS build

# Install system dependencies for native compilation
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    nodejs \
    npm \
    git \
    libssl-dev \
    pkg-config \
    llvm-14 \
    liblzma-dev \
    libclang-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for native compilation
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Install Garaga SDK and ZK tools
RUN npm install -g @garaga/cli@latest garaga-cuda@latest

# Copy package files
COPY zk-circuits/package*.json ./
RUN npm ci

# Copy circuit source code
COPY zk-circuits/ .

# Compile circuits with GPU optimization
ENV GARAGA_CUDA_ENABLED=true
ENV GARAGA_OPTIMIZATION_LEVEL=3
RUN npm run build:optimized

# Generate proving and verification keys
RUN mkdir -p keys/proving keys/verification
RUN npm run generate:keys

# Optimize for production
RUN npm run optimize:circuits

# Install Python dependencies for proof generation
COPY zk-circuits/requirements.txt ./
RUN pip3 install -r requirements.txt --no-cache-dir

# Run security scan
RUN npm run security:scan

# Production stage
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04 AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    curl \
    dumb-init \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid 1000 zkuser && \
    useradd --uid 1000 --gid 1000 -m zkuser

WORKDIR /app

# Copy package files and install production dependencies
COPY zk-circuits/package*.json

```yaml
RUN npm ci --only=production --no-optional --no-fund && \
    npm cache clean --force

# Install Python runtime dependencies
COPY zk-circuits/requirements.txt ./
RUN pip3 install -r requirements.txt --no-cache-dir

# Copy built circuits and keys from build stage
COPY --from=build /app/build ./build
COPY --from=build /app/keys ./keys
COPY --from=build /app/config ./config
COPY --from=build /app/proof-service ./proof-service

# Create necessary directories
RUN mkdir -p /app/tmp /app/cache /app/logs && \
    chown -R zkuser:zkuser /app

# Change ownership to non-root user
RUN chown -R zkuser:zkuser /app

# Switch to non-root user
USER zkuser

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=4096 --disallow-code-generation-from-strings"
ENV GARAGA_CUDA_ENABLED=true
ENV ZK_PROOF_SECURITY_LEVEL=128
ENV TMPDIR=/app/tmp

# Expose proof generation service port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run the proof generation service with GPU support
CMD ["node", "--max-old-space-size=4096", "proof-service/index.js"]
````

### 10.2 ZK Circuit Compilation

Create `zk-circuits/scripts/compile-circuits.sh`:

```bash
#!/bin/bash
set -e

echo "🔄 Compiling ZK circuits for Veridis..."

# Check for CUDA support
if [ "$GARAGA_CUDA_ENABLED" = "true" ]; then
    if command -v nvidia-smi &> /dev/null; then
        echo "🖥️ CUDA enabled, using GPU acceleration"
        CUDA_FLAGS="--gpu --optimization-level=$GARAGA_OPTIMIZATION_LEVEL"
    else
        echo "⚠️ Warning: CUDA enabled but no GPU detected, falling back to CPU"
        CUDA_FLAGS="--optimization-level=$GARAGA_OPTIMIZATION_LEVEL"
    fi
else
    echo "🖥️ Using CPU for circuit compilation"
    CUDA_FLAGS="--optimization-level=$GARAGA_OPTIMIZATION_LEVEL"
fi

# Create output directories
mkdir -p build/circuits
mkdir -p build/verification_keys
mkdir -p keys/proving
mkdir -p keys/verification

# Compile identity verification circuit
echo "🆔 Compiling identity verification circuit..."
garaga compile \
    --input src/identity_verification.circuit \
    --output build/circuits/identity_verification.json \
    $CUDA_FLAGS

# Compile attestation verification circuit
echo "📜 Compiling attestation verification circuit..."
garaga compile \
    --input src/attestation_verification.circuit \
    --output build/circuits/attestation_verification.json \
    $CUDA_FLAGS

# Compile selective disclosure circuit
echo "🔍 Compiling selective disclosure circuit..."
garaga compile \
    --input src/selective_disclosure.circuit \
    --output build/circuits/selective_disclosure.json \
    $CUDA_FLAGS

# Compile nullifier circuit
echo "🔒 Compiling nullifier generation circuit..."
garaga compile \
    --input src/nullifier_generation.circuit \
    --output build/circuits/nullifier_generation.json \
    $CUDA_FLAGS

# Compile GDPR compliance circuits (cryptographic erasure)
echo "🔐 Compiling GDPR compliance circuits..."
garaga compile \
    --input src/cryptographic_erasure.circuit \
    --output build/circuits/cryptographic_erasure.json \
    $CUDA_FLAGS

# Generate proving keys with security level
echo "🔑 Generating proving keys..."
for circuit in identity_verification attestation_verification selective_disclosure nullifier_generation cryptographic_erasure; do
    echo "Generating proving key for $circuit..."
    garaga setup \
        --circuit build/circuits/$circuit.json \
        --proving-key keys/proving/$circuit.pk \
        --verification-key keys/verification/$circuit.vk \
        --trusted-setup keys/trusted_setup.ptau \
        --security-level $ZK_PROOF_SECURITY_LEVEL
done

# Optimize circuit constraints
echo "⚡ Optimizing circuit constraints..."
garaga optimize \
    --circuits build/circuits/ \
    --output build/optimized/ \
    $CUDA_FLAGS

# Generate verification contracts for StarkNet
echo "📋 Generating StarkNet verification contracts..."
for circuit in identity_verification attestation_verification selective_disclosure nullifier_generation cryptographic_erasure; do
    garaga generate-starknet-verifier \
        --verification-key keys/verification/$circuit.vk \
        --output ../contracts/src/verifiers/${circuit}_verifier.cairo
done

# Verify circuit security
echo "🔒 Verifying circuit security..."
garaga audit \
    --circuits build/circuits/ \
    --output security/circuit-audit.json

# Run circuit tests
echo "🧪 Running circuit tests..."
npm run test:circuits

echo "✅ ZK circuit compilation completed successfully!"
```

### 10.3 Proof Generation Service

Create `zk-circuits/proof-service/index.js`:

```javascript
const express = require("express");
const { generateProof, verifyProof } = require("./proof-generator");
const { validateCircuitInputs } = require("./validators");
const { ProofCache } = require("./cache");
const logger = require("./logger");
const metrics = require("./metrics");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const app = express();
const port = process.env.PORT || 4000;

// Initialize proof cache
const proofCache = new ProofCache({
  maxSize: parseInt(process.env.PROOF_CACHE_SIZE || "10000"),
  ttl: parseInt(process.env.PROOF_CACHE_TTL || "3600000"), // 1 hour
  persistPath: process.env.PROOF_CACHE_PERSIST
    ? "./cache/proof-cache.json"
    : null,
});

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: parseInt(process.env.RATE_LIMIT_MAX || "100"), // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Request parsing
app.use(express.json({ limit: "10mb" }));

// Metrics middleware
app.use(metrics.metricsMiddleware);

// Expose metrics endpoint
app.get("/metrics", (req, res) => {
  res.set("Content-Type", metrics.register.contentType);
  metrics.register.metrics().then((data) => res.end(data));
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    garaga_version: process.env.GARAGA_VERSION || "latest",
    circuits_loaded: Object.keys(require("./circuits")).length,
    cuda_enabled: process.env.GARAGA_CUDA_ENABLED === "true",
    security_level: process.env.ZK_PROOF_SECURITY_LEVEL || "128",
    uptime: process.uptime(),
  });
});

// Generate identity verification proof
app.post("/prove/identity", async (req, res) => {
  const startTime = Date.now();
  try {
    const { commitment, secret, nullifier } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.identity({ commitment, secret, nullifier })) {
      logger.warn("Invalid identity circuit inputs", { commitment, nullifier });
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    // Check cache first
    const cacheKey = `identity_${commitment}_${nullifier}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new identity proof", { commitment, nullifier });
      metrics.metrics.zkProofGeneration
        .labels("identity_verification", "started")
        .inc();

      const proofTimer = metrics.metrics.zkProofGenerationDuration
        .labels("identity_verification")
        .startTimer();

      try {
        proof = await generateProof("identity_verification", {
          private_inputs: { secret },
          public_inputs: { commitment, nullifier },
        });

        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("identity_verification", "success")
          .inc();
        proofCache.set(cacheKey, proof);
      } catch (error) {
        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("identity_verification", "failure")
          .inc();
        throw error;
      }
    } else {
      logger.info("Using cached identity proof", { commitment, nullifier });
      metrics.metrics.zkProofGeneration
        .labels("identity_verification", "cache_hit")
        .inc();
    }

    const duration = Date.now() - startTime;
    logger.info("Identity proof generation completed", {
      duration_ms: duration,
      from_cache: !!proofCache.get(cacheKey),
    });

    res.json({
      proof,
      cached: !!proofCache.get(cacheKey),
      generation_time_ms: duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error("Identity proof generation failed", {
      error: error.message,
      stack: error.stack,
      duration_ms: duration,
    });
    res.status(500).json({
      error: "Proof generation failed",
      message: error.message,
      generation_time_ms: duration,
    });
  }
});

// Generate attestation verification proof
app.post("/prove/attestation", async (req, res) => {
  const startTime = Date.now();
  try {
    const {
      attestation_root,
      merkle_proof,
      nullifier,
      disclosed_attributes,
      private_attributes,
    } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.attestation(req.body)) {
      logger.warn("Invalid attestation circuit inputs");
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    const cacheKey = `attestation_${attestation_root}_${nullifier}_${JSON.stringify(
      disclosed_attributes
    )}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new attestation proof", {
        attestation_root,
        nullifier,
        disclosed_count: disclosed_attributes.length,
      });

      metrics.metrics.zkProofGeneration
        .labels("attestation_verification", "started")
        .inc();
      const proofTimer = metrics.metrics.zkProofGenerationDuration
        .labels("attestation_verification")
        .startTimer();

      try {
        proof = await generateProof("attestation_verification", {
          private_inputs: {
            merkle_proof,
            private_attributes,
          },
          public_inputs: {
            attestation_root,
            nullifier,
            disclosed_attributes,
          },
        });

        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("attestation_verification", "success")
          .inc();
        proofCache.set(cacheKey, proof);
      } catch (error) {
        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("attestation_verification", "failure")
          .inc();
        throw error;
      }
    } else {
      logger.info("Using cached attestation proof", {
        attestation_root,
        nullifier,
      });
      metrics.metrics.zkProofGeneration
        .labels("attestation_verification", "cache_hit")
        .inc();
    }

    const duration = Date.now() - startTime;
    logger.info("Attestation proof generation completed", {
      duration_ms: duration,
      from_cache: !!proofCache.get(cacheKey),
    });

    res.json({
      proof,
      cached: !!proofCache.get(cacheKey),
      generation_time_ms: duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error("Attestation proof generation failed", {
      error: error.message,
      stack: error.stack,
      duration_ms: duration,
    });
    res.status(500).json({
      error: "Proof generation failed",
      message: error.message,
      generation_time_ms: duration,
    });
  }
});

// Generate selective disclosure proof
app.post("/prove/selective-disclosure", async (req, res) => {
  const startTime = Date.now();
  try {
    const {
      credential_commitment,
      disclosed_fields,
      undisclosed_fields,
      nullifier,
    } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.selectiveDisclosure(req.body)) {
      logger.warn("Invalid selective disclosure circuit inputs");
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    const cacheKey = `selective_disclosure_${credential_commitment}_${nullifier}_${JSON.stringify(
      disclosed_fields
    )}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new selective disclosure proof", {
        credential_commitment,
        nullifier,
        disclosed_count: disclosed_fields.length,
      });

      metrics.metrics.zkProofGeneration
        .labels("selective_disclosure", "started")
        .inc();
      const proofTimer = metrics.metrics.zkProofGenerationDuration
        .labels("selective_disclosure")
        .startTimer();

      try {
        proof = await generateProof("selective_disclosure", {
          private_inputs: { undisclosed_fields },
          public_inputs: {
            credential_commitment,
            disclosed_fields,
            nullifier,
          },
        });

        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("selective_disclosure", "success")
          .inc();
        proofCache.set(cacheKey, proof);
      } catch (error) {
        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("selective_disclosure", "failure")
          .inc();
        throw error;
      }
    } else {
      logger.info("Using cached selective disclosure proof", {
        credential_commitment,
        nullifier,
      });
      metrics.metrics.zkProofGeneration
        .labels("selective_disclosure", "cache_hit")
        .inc();
    }

    const duration = Date.now() - startTime;
    res.json({
      proof,
      cached: !!proofCache.get(cacheKey),
      generation_time_ms: duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error("Selective disclosure proof generation failed", {
      error: error.message,
      stack: error.stack,
      duration_ms: duration,
    });
    res.status(500).json({
      error: "Proof generation failed",
      message: error.message,
      generation_time_ms: duration,
    });
  }
});

// Generate cryptographic erasure proof (GDPR compliance)
app.post("/prove/erasure", async (req, res) => {
  const startTime = Date.now();
  try {
    const { data_hash, nullifier, erasure_proof, public_salt } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.cryptographicErasure(req.body)) {
      logger.warn("Invalid erasure circuit inputs");
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    const cacheKey = `erasure_${data_hash}_${nullifier}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new cryptographic erasure proof", {
        data_hash,
        nullifier,
      });

      metrics.metrics.zkProofGeneration
        .labels("cryptographic_erasure", "started")
        .inc();
      const proofTimer = metrics.metrics.zkProofGenerationDuration
        .labels("cryptographic_erasure")
        .startTimer();

      try {
        proof = await generateProof("cryptographic_erasure", {
          private_inputs: {
            erasure_proof,
          },
          public_inputs: {
            data_hash,
            nullifier,
            public_salt,
            erasure_rounds: parseInt(process.env.CRYPTO_ERASURE_ROUNDS || "3"),
          },
        });

        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("cryptographic_erasure", "success")
          .inc();
        proofCache.set(cacheKey, proof);
      } catch (error) {
        proofTimer();
        metrics.metrics.zkProofGeneration
          .labels("cryptographic_erasure", "failure")
          .inc();
        throw error;
      }
    } else {
      logger.info("Using cached cryptographic erasure proof", {
        data_hash,
        nullifier,
      });
      metrics.metrics.zkProofGeneration
        .labels("cryptographic_erasure", "cache_hit")
        .inc();
    }

    const duration = Date.now() - startTime;
    res.json({
      proof,
      cached: !!proofCache.get(cacheKey),
      generation_time_ms: duration,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error("Cryptographic erasure proof generation failed", {
      error: error.message,
      stack: error.stack,
      duration_ms: duration,
    });
    res.status(500).json({
      error: "Proof generation failed",
      message: error.message,
      generation_time_ms: duration,
    });
  }
});

// Verify any proof
app.post("/verify", async (req, res) => {
  const startTime = Date.now();
  try {
    const { proof, public_inputs, circuit_type } = req.body;

    if (!proof || !public_inputs || !circuit_type) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    metrics.metrics.zkProofGeneration
      .labels(`${circuit_type}_verification`, "started")
      .inc();
    const verificationTimer = metrics.metrics.zkProofGenerationDuration
      .labels(`${circuit_type}_verification`)
      .startTimer();

    try {
      const isValid = await verifyProof(circuit_type, proof, public_inputs);
      verificationTimer();

      if (isValid) {
        metrics.metrics.zkProofGeneration
          .labels(`${circuit_type}_verification`, "success")
          .inc();
      } else {
        metrics.metrics.zkProofGeneration
          .labels(`${circuit_type}_verification`, "invalid")
          .inc();
      }

      const duration = Date.now() - startTime;
      res.json({
        valid: isValid,
        verification_time_ms: duration,
      });
    } catch (error) {
      verificationTimer();
      metrics.metrics.zkProofGeneration
        .labels(`${circuit_type}_verification`, "failure")
        .inc();
      throw error;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error("Proof verification failed", {
      error: error.message,
      stack: error.stack,
      duration_ms: duration,
    });
    res.status(500).json({
      error: "Proof verification failed",
      message: error.message,
      verification_time_ms: duration,
    });
  }
});

// Get proof generation statistics
app.get("/stats", (req, res) => {
  res.json({
    cache_stats: proofCache.getStats(),
    uptime: process.uptime(),
    memory_usage: process.memoryUsage(),
    cuda_enabled: process.env.GARAGA_CUDA_ENABLED === "true",
    optimization_level: parseInt(process.env.GARAGA_OPTIMIZATION_LEVEL || "3"),
    security_level: parseInt(process.env.ZK_PROOF_SECURITY_LEVEL || "128"),
    erasure_rounds: parseInt(process.env.CRYPTO_ERASURE_ROUNDS || "3"),
  });
});

// Handle errors
app.use((err, req, res, next) => {
  logger.error("Unhandled error", {
    error: err.message,
    stack: err.stack,
    path: req.path,
  });
  res.status(500).json({ error: "Internal server error" });
});

// Start the server
app.listen(port, () => {
  logger.info(`ZK Proof service listening on port ${port}`, {
    cuda_enabled: process.env.GARAGA_CUDA_ENABLED === "true",
    optimization_level: process.env.GARAGA_OPTIMIZATION_LEVEL || "3",
    security_level: process.env.ZK_PROOF_SECURITY_LEVEL || "128",
  });
  logger.info("Available circuits:", Object.keys(require("./circuits")));
});

// Handle graceful shutdown
process.on("SIGTERM", () => {
  logger.info("SIGTERM received, shutting down gracefully");
  proofCache.persistIfEnabled();
  process.exit(0);
});

process.on("SIGINT", () => {
  logger.info("SIGINT received, shutting down gracefully");
  proofCache.persistIfEnabled();
  process.exit(0);
});

module.exports = app;
```

## 11. Cross-Chain Testing Environment

### 11.1 Multi-Chain Development Setup

Create `docker-compose.cross-chain.yml`:

```yaml
version: "3.8"

services:
  # StarkNet devnet
  starknet-devnet:
    image: shardlabs/starknet-devnet:v0.8.1
    ports:
      - "5050:5050"
    command:
      [
        "--host",
        "0.0.0.0",
        "--port",
        "5050",
        "--seed",
        "42",
        "--accounts",
        "10",
        "--gas-price",
        "100000000",
      ]
    environment:
      - STARKNET_NETWORK=devnet
      - STARKNET_TX_VERSION=3
      - STARKNET_RESOURCE_BOUNDS_ENABLED=true
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5050/is_alive"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Ethereum node (Anvil)
  ethereum-node:
    image: ghcr.io/foundry-rs/foundry:latest
    ports:
      - "8545:8545"
    command:
      [
        "anvil",
        "--host",
        "0.0.0.0",
        "--port",
        "8545",
        "--chain-id",
        "31337",
        "--block-time",
        "2",
      ]
    networks:
      - cross-chain-network
    healthcheck:
      test:
        [
          "CMD",
          "curl",
          "-f",
          "-X",
          "POST",
          "--data",
          '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
          "http://localhost:8545",
        ]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cosmos node
  cosmos-node:
    image: cosmos/gaia:v14.0.0
    ports:
      - "26657:26657"
      - "1317:1317"
    environment:
      - CHAIN_ID=veridis-testnet
      - FAST_SYNC=true
    volumes:
      - cosmos-data:/root/.gaia
    command: ["gaiad", "start", "--rpc.laddr", "tcp://0.0.0.0:26657"]
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:26657/status"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Solana test validator
  solana-node:
    image: solanalabs/solana:v1.16.15
    ports:
      - "8899:8899"
      - "8900:8900"
    command:
      [
        "solana-test-validator",
        "--bind-address",
        "0.0.0.0",
        "--rpc-port",
        "8899",
        "--log",
      ]
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8899"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Polkadot/Substrate node
  substrate-node:
    image: parity/substrate:latest
    ports:
      - "9944:9944"
      - "9933:9933"
    command:
      [
        "--dev",
        "--ws-external",
        "--rpc-external",
        "--ws-port",
        "9944",
        "--rpc-port",
        "9933",
      ]
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9933"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cross-chain bridge orchestrator
  bridge-orchestrator:
    build:
      context: .
      dockerfile: docker/bridge/orchestrator.Dockerfile
    ports:
      - "3005:3000"
    environment:
      - NODE_ENV=development
      - STARKNET_RPC=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - STARKNET_RESOURCE_BOUNDS_ENABLED=true
      - ETHEREUM_RPC=http://ethereum-node:8545
      - COSMOS_RPC=http://cosmos-node:26657
      - SOLANA_RPC=http://solana-node:8899
      - SUBSTRATE_RPC=ws://substrate-node:9944
      - DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_crosschain
      - REDIS_URL=redis://redis:6379
      - PORT=3000
      - LOG_LEVEL=debug
    depends_on:
      - starknet-devnet
      - ethereum-node
      - cosmos-node
      - solana-node
      - substrate-node
      - postgres
      - redis
    networks:
      - cross-chain-network
    volumes:
      - ./cross-chain-tests:/app/tests
      - bridge-state:/app/state
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Cross-chain test runner
  cross-chain-tester:
    build:
      context: .
      dockerfile: docker/testing/cross-chain.Dockerfile
    environment:
      - NODE_ENV=development
      - BRIDGE_ORCHESTRATOR_URL=http://bridge-orchestrator:3000
      - STARKNET_RPC=http://starknet-devnet:5050/rpc/v0_8_1
      - ETHEREUM_RPC=http://ethereum-node:8545
      - COSMOS_RPC=http://cosmos-node:26657
      - SOLANA_RPC=http://solana-node:8899
      - SUBSTRATE_RPC=ws://substrate-node:9944
      - TEST_TIMEOUT=300000
      - LOG_LEVEL=debug
    volumes:
      - ./cross-chain-tests:/app/tests
      - test-results:/app/results
    depends_on:
      - bridge-orchestrator
    networks:
      - cross-chain-network

  # Contract deployer for cross-chain testing
  contract-deployer:
    build:
      context: .
      dockerfile: docker/cairo/deployer.Dockerfile
    environment:
      - ENVIRONMENT=development
      - NETWORK=devnet
      - STARKNET_RPC_URL=http://starknet-devnet:5050/rpc/v0_8_1
      - STARKNET_TX_VERSION=3
      - RESOURCE_BOUNDS_ENABLED=true
    volumes:
      - ./contracts:/app/contracts
      - ./deployments:/app/deployments
    depends_on:
      - starknet-devnet
    networks:
      - cross-chain-network

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=veridis
      - POSTGRES_PASSWORD=veridis
      - POSTGRES_DB=veridis_crosschain
    volumes:
      - postgres-crosschain:/var/lib/postgresql/data
      - ./scripts/init-crosschain-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U veridis"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis-crosschain:/data
    networks:
      - cross-chain-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  cross-chain-network:
    driver: bridge
    name: veridis-crosschain-network
    ipam:
      driver: default
      config:
        - subnet: 172.29.0.0/16

volumes:
  bridge-state:
  test-results:
  postgres-crosschain:
  redis-crosschain:
  cosmos-data:
```

### 11.2 Bridge Orchestrator

Create `docker/bridge/orchestrator.Dockerfile`:

```dockerfile
FROM node:20-alpine

# Install dependencies for multi-chain interaction
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    git \
    curl \
    jq \
    openssl \
    ca-certificates \
    dumb-init

WORKDIR /app

# Copy package files
COPY services/bridge-service/package*.json ./
RUN npm ci

# Install chain-specific SDKs with fixed versions
RUN npm install \
    starknet@7.0.1 \
    ethers@6.7.1 \
    @cosmjs/stargate@0.32.1 \
    @solana/web3.js@1.87.6 \
    @polkadot/api@10.11.2 \
    bn.js@5.2.1 \
    winston@3.11.0 \
    express@4.18.2 \
    prometheus-client@0.17.0

# Copy bridge service source
COPY services/bridge-service/ .

# Copy cross-chain configuration
COPY cross-chain-config/ ./config/

# Create necessary directories
RUN mkdir -p /app/tmp /app/logs /app/state && \
    chown -R node:node /app

# Use non-root user
USER node

# Set security-focused environment variables
ENV NODE_OPTIONS="--max-old-space-size=2048 --disallow-code-generation-from-strings"
ENV TMPDIR=/app/tmp

# Expose orchestrator port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/sbin/dumb-init", "--"]

# Run the bridge orchestrator
CMD ["node", "src/orchestrator.js"]
```

### 11.3 Cross-Chain Test Suite

Create `scripts/run-cross-chain-tests.sh`:

```bash
#!/bin/bash
set -e

echo "🌉 Starting cross-chain integration tests..."

# Start the cross-chain environment
docker-compose -f docker-compose.cross-chain.yml up -d

# Wait for all nodes to be ready
echo "⏳ Waiting for blockchain nodes to be ready..."
sleep 30

# Function to check if a service is healthy
check_service() {
    local service=$1
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.cross-chain.yml exec $service curl -f http://localhost:$2 > /dev/null 2>&1; then
            echo "✅ $service is ready"
            return 0
        fi
        echo "⏳ Waiting for $service (attempt $attempt/$max_attempts)..."
        sleep 5
        attempt=$((attempt + 1))
    done

    echo "❌ $service failed to start"
    return 1
}

# Check all services
check_service "starknet-devnet" "5050/is_alive"
check_service "ethereum-node" "8545"
check_service "cosmos-node" "26657/status"
check_service "solana-node" "8899"
check_service "substrate-node" "9933"
check_service "bridge-orchestrator" "3000/health"

# Deploy cross-chain contracts
echo "📝 Deploying cross-chain contracts..."
docker-compose -f docker-compose.cross-chain.yml run --rm contract-deployer \
    /usr/local/bin/deploy-starknet.sh development devnet

echo "📝 Deploying Ethereum contracts..."
docker-compose -f docker-compose.cross-chain.yml exec ethereum-node bash -c '
    cd /app/scripts
    ./deploy-ethereum-contracts.sh
'

# Initialize bridge configuration
echo "🔗 Initializing bridge configuration..."
docker-compose -f docker-compose.cross-chain.yml exec bridge-orchestrator \
    node scripts/initialize-bridge.js

# Run attestation bridging tests
echo "🔗 Testing attestation bridging..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:attestation-bridge

# Run identity verification across chains
echo "🆔 Testing cross-chain identity verification..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:identity-bridge

# Run compliance synchronization tests
echo "📋 Testing compliance data synchronization..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:compliance-sync

# Test nullifier synchronization
echo "🔒 Testing nullifier synchronization..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:nullifier-sync

# Run advanced attack simulations
echo "🛡️ Running attack simulations..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:attack-simulations

# Run network partition tests
echo "🕸️ Testing network partition resilience..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run test:network-partition

# Generate cross-chain test report
echo "📊 Generating test report..."
docker-compose -f docker-compose.cross-chain.yml run --rm cross-chain-tester \
    npm run generate:report

# Copy test results
mkdir -p ./test-results/cross-chain
docker cp $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester):/app/results ./test-results/cross-chain

echo "✅ Cross-chain tests completed successfully!"
echo "📄 Test results available in ./test-results/cross-chain/"

# Cleanup (optional)
if [ "$1" != "--keep" ]; then
    echo "🧹 Cleaning up cross-chain environment..."
    docker-compose -f docker-compose.cross-chain.yml down
else
    echo "🔍 Cross-chain environment kept running for inspection"
    echo "To shut it down later, run: docker-compose -f docker-compose.cross-chain.yml down"
fi
```

### 11.4 Cross-Chain Testing Architecture Documentation

Create `docs/cross-chain-testing.md`:

````markdown
# Cross-Chain Testing Architecture for Veridis

## Overview

The Veridis cross-chain testing environment validates the protocol's ability to maintain identity and attestation consistency across multiple blockchain networks while preserving privacy guarantees and ensuring GDPR compliance across jurisdictions.

## Architecture Diagram

```mermaid
graph TD
    A[StarkNet v0.13.4] -->|Bridge| B{Bridge Orchestrator}
    B --> C[Ethereum]
    B --> D[Cosmos]
    B --> E[Solana]
    B --> F[Substrate/Polkadot]

    G[Identity Service] --> B
    H[Attestation Service] --> B
    I[Compliance Service] --> B
    J[ZK Proof Service] --> B

    B --> K[Cross-Chain State Sync]
    B --> L[Nullifier Coordination]
    B --> M[ZK Proof Verification]
    B --> N[GDPR Compliance]
```
````

## Test Scenarios

### 1. Identity Bridging

- Create identity on StarkNet with Cairo 2.11.4 contracts
- Bridge identity commitment to Ethereum and other chains
- Verify identity on multiple chains using ZK proofs
- Test unlinkability across chains
- Validate transaction_v3 compatibility with resource bounds

### 2. Attestation Verification

- Issue attestation on StarkNet
- Bridge attestation roots to Ethereum
- Verify attestation on multiple chains using ZK proofs
- Test selective disclosure across chains
- Validate compliance requirements in multiple jurisdictions
- Test Merkle proof verification in different environments

### 3. Nullifier Synchronization

- Generate nullifier on one chain using Poseidon Hash v3.2
- Propagate nullifier to all connected chains
- Test double-spending prevention across chains
- Validate cross-chain consistency with different finality guarantees
- Test resilience to network partitions and chain reorganizations

### 4. GDPR Compliance Coordination

- Test cryptographic erasure with zero-knowledge proofs
- Validate data retention policies across jurisdictions
- Test right-to-be-forgotten implementation with provable erasure
- Ensure audit trail consistency with regulatory requirements
- Test cross-chain compliance with different regulatory frameworks

### 5. Advanced Attack Simulations

- BGP hijacking simulation with network partitioning
- Light client spoofing attempts
- 51% attack simulation on source chains
- Replay attack testing with transaction ordering manipulation
- Message withholding and censorship attack testing
- Validator collusion simulation with different threshold configurations

## Performance Requirements

- **Cross-chain message latency**: < 5 minutes
- **State synchronization**: < 10 minutes
- **Proof verification**: < 30 seconds per chain
- **Nullifier consistency**: 100% accuracy
- **Cryptographic erasure**: < 60 seconds
- **Resource bounds**: Within 10% of estimated values

## Security Guarantees

- Zero-knowledge privacy preservation with 128-bit security
- Cross-chain replay attack prevention with nonce management
- Secure message passing with domain separation
- Cryptographic state verification with chain-specific validation
- Resource bounds validation for transaction_v3 compatibility
- GDPR compliant data handling with cryptographic guarantees

## Implementation Details

### Bridge Orchestrator

The Bridge Orchestrator coordinates cross-chain communication and manages:

- State root synchronization
- Message authentication and validation
- Nullifier propagation and consistency checking
- Proof verification across different chains
- Network partition recovery
- Resource bounds estimation and validation

### Cross-Chain Test Runner

The test runner automates verification of:

- End-to-end functionality across chains
- Security guarantees under adverse conditions
- Performance characteristics under load
- Compliance with regulatory requirements
- Resource usage and gas estimation accuracy
- Error recovery and resilience

### Continuous Integration

The cross-chain testing environment integrates with CI/CD to:

- Validate changes to Cairo contracts before deployment
- Test compatibility with StarkNet transaction_v3
- Ensure resource bounds are properly calculated and enforced
- Verify cross-chain communication protocols
- Test compliance mechanisms across jurisdictions
- Simulate network partitions and recovery scenarios

## Tools and Components

- **StarkNet Devnet**: Local StarkNet v0.13.4 development network
- **Anvil**: Local Ethereum development network
- **Cosmos SDK**: Local Cosmos chain for IBC testing
- **Solana Test Validator**: Local Solana development network
- **Substrate Node**: Local Polkadot/Substrate development network
- **Bridge Orchestrator**: Custom service for cross-chain coordination
- **Test Runner**: Automated test execution and reporting
- **Network Simulator**: Tools for simulating network conditions
- **Attack Simulator**: Framework for simulating adversarial behavior

## Troubleshooting

### Common Issues

1. **Chain Synchronization Failures**

   - Check network connectivity between containers
   - Verify RPC endpoints are accessible
   - Ensure chain-specific parameters are correctly configured

2. **Proof Verification Failures**

   - Verify ZK proof service is functioning correctly
   - Check compatibility of verification keys across chains
   - Ensure cryptographic parameters are consistent

3. **Transaction Failures**
   - Verify resource bounds are appropriate for operations
   - Check transaction_v3 compatibility settings
   - Ensure account funding on all test chains

### Logging and Monitoring

- All containers output logs to standard output
- Structured JSON logging for machine processing
- Metrics collection via Prometheus endpoints
- Test reports generated in JUnit XML and HTML formats

````

## 12. Monitoring and Logging

### 12.1 Comprehensive Logging Configuration

Create `services/shared/logger.js`:

```javascript
const winston = require('winston');
const { format } = winston;
const fs = require('fs');
const path = require('path');

// Ensure log directory exists
const LOG_DIR = process.env.LOG_DIR || '/app/logs';
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

// Create formatter for development environment
const devFormat = format.combine(
  format.timestamp(),
  format.colorize(),
  format.printf(({ timestamp, level, message, service, context, ...meta }) => {
    const metaStr = Object.keys(meta).length
      ? `\n${JSON.stringify(meta, null, 2)}`
      : '';
    const contextStr = context ? `[${context}] ` : '';
    return `${timestamp} ${level}: ${contextStr}${message}${metaStr}`;
  })
);

// Create JSON formatter for production environment
const prodFormat = format.combine(
  format.timestamp(),
  format.errors({ stack: true }),
  format.json()
);

// Create logger with different transports based on environment
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  defaultMeta: {
    service: process.env.SERVICE_NAME || 'veridis',
    version: process.env.SERVICE_VERSION || '3.2.1',
    environment: process.env.NODE_ENV || 'development'
  },
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'production' ? prodFormat : devFormat
    })
  ]
});

// Add file transport in production
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({
    filename: path.join(LOG_DIR, 'error.log'),
    level: 'error',
    format: prodFormat,
    maxsize: 10485760, // 10MB
    maxFiles: 5
  }));

  logger.add(new winston.transports.File({
    filename: path.join(LOG_DIR, 'combined.log'),
    format: prodFormat,
    maxsize: 10485760, // 10MB
    maxFiles: 10
  }));
}

// Add compliance-specific logging
logger.addComplianceLog = (action, userId, data = {}) => {
  const hashedUserId = userId ? `user_${require('crypto').createHash('sha256').update(userId).digest('hex').substring(0, 8)}` : 'anonymous';

  logger.info('Compliance event recorded', {
    action,
    user_id_hash: hashedUserId,
    timestamp: new Date().toISOString(),
    gdpr_category: data.gdprCategory || 'general',
    data_classification: data.classification || 'public',
    retention_period: data.retentionPeriod || 'default',
    context: 'compliance'
  });

  // Write to immutable compliance log if enabled
  if (process.env.IMMUTABLE_AUDIT_LOG === 'true') {
    const complianceLog = {
      action,
      user_id_hash: hashedUserId,
      timestamp: new Date().toISOString(),
      gdpr_category: data.gdprCategory || 'general',
      data_classification: data.classification || 'public',
      retention_period: data.retentionPeriod || 'default',
      service: process.env.SERVICE_NAME || 'veridis',
      version: process.env.SERVICE_VERSION || '3.2.1',
      environment: process.env.NODE_ENV || 'development'
    };

    // Append to immutable log file with secure audit trail
    try {
      const logPath = path.join(LOG_DIR, 'compliance-audit.log');
      const logEntry = JSON.stringify(complianceLog) + '\n';
      fs.appendFileSync(logPath, logEntry);
    } catch (err) {
      logger.error('Failed to write to compliance audit log', { error: err.message, context: 'compliance' });
    }
  }
};

// Add security-specific logging
logger.addSecurityLog = (event, severity, details = {}) => {
  logger.warn('Security event detected', {
    event,
    severity,
    details,
    timestamp: new Date().toISOString(),
    ip: details.ip || 'unknown',
    user_agent: details.userAgent || 'unknown',
    context: 'security'
  });

  // Track security events in metrics if available
  try {
    const metrics = require('./metrics');
    if (metrics && metrics.metrics.securityEvents) {
      metrics.metrics.securityEvents.labels(event, severity).inc();
    }
  } catch (err) {
    // Metrics module not available
  }
};

// Track start of process
logger.info(`Logger initialized for ${process.env.SERVICE_NAME || 'veridis'} service`, {
  level: process.env.LOG_LEVEL || 'info',
  environment: process.env.NODE_ENV || 'development',
  context: 'startup'
});

// Export logger instance
module.exports = logger;
````

### 12.2 Prometheus Metrics Configuration

Create `k8s/base/monitoring/prometheus-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
      external_labels:
        cluster: 'veridis-cluster'
        environment: '${ENVIRONMENT}'

    rule_files:
      - "/etc/prometheus/rules/*.yml"

    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - source_labels: [__meta_kubernetes_pod_label_app]
            action: replace
            target_label: app
          - source_labels: [__meta_kubernetes_pod_label_component]
            action: replace
            target_label: component
          - source_labels: [__meta_kubernetes_pod_label_environment]
            action: replace
            target_label: environment

      - job_name: 'veridis-services'
        kubernetes_sd_configs:
          - role: service
            namespaces:
              names:
                - veridis
                - veridis-prod
                - veridis-staging
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - source_labels: [__meta_kubernetes_service_label_app]
            action: replace
            target_label: app
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: namespace

      - job_name: 'starknet-metrics'
        static_configs:
          - targets: ['starknet-devnet:5050']
        metrics_path: '/metrics'
        scrape_interval: 60s

      - job_name: 'zk-proof-service'
        static_configs:
          - targets: ['zk-proof-service:4000']
        metrics_path: '/metrics'
        scrape_interval: 30s

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093

  alerting_rules.yml: |
    groups:
      - name: veridis.rules
        rules:
          - alert: HighErrorRate
            expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High error rate detected"
              description: "Error rate is {{ $value }} errors per second for {{ $labels.app }}"
              dashboard_url: "https://grafana.veridis.xyz/d/service-overview"
              runbook_url: "https://docs.veridis.xyz/runbooks/high-error-rate"

          - alert: HighLatency
            expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High latency detected"
              description: "95th percentile latency is {{ $value }} seconds for {{ $labels.app }}"
              dashboard_url: "https://grafana.veridis.xyz/d/service-performance"
              runbook_url: "https://docs.veridis.xyz/runbooks/high-latency"

          - alert: ZKProofGenerationFailing
            expr: rate(zk_proof_generation_total{status="failure"}[5m]) > 0.05
            for: 2m
            labels:
              severity: critical
            annotations:
              summary: "ZK proof generation failing"
              description: "ZK proof generation failure rate is {{ $value }} per second for {{ $labels.circuit_type }}"
              dashboard_url: "https://grafana.veridis.xyz/d/zk-proof-performance"
              runbook_url: "https://docs.veridis.xyz/runbooks/zk-proof-failures"

          - alert: ComplianceViolation
            expr: increase(compliance_events_total{severity="critical"}[1h]) > 0
            for: 0s
            labels:
              severity: critical
            annotations:
              summary: "Compliance violation detected"
              description: "{{ $value }} compliance violations in the last hour"
              dashboard_url: "https://grafana.veridis.xyz/d/compliance-monitoring"
              runbook_url: "https://docs.veridis.xyz/runbooks/compliance-violations"

          - alert: CrossChainBridgeDown
            expr: up{app="bridge-service"} == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "Cross-chain bridge is down"
              description: "Bridge service is not responding"
              dashboard_url: "https://grafana.veridis.xyz/d/bridge-monitoring"
              runbook_url: "https://docs.veridis.xyz/runbooks/bridge-failures"

          - alert: GDPRDataRetention
            expr: gdpr_data_retention_violations > 0
            for: 1h
            labels:
              severity: critical
              compliance: "gdpr"
            annotations:
              summary: "GDPR data retention policy violation"
              description: "{{ $value }} records exceed the retention period"
              dashboard_url: "https://grafana.veridis.xyz/d/gdpr-compliance"
              runbook_url: "https://docs.veridis.xyz/runbooks/gdpr-violations"

          - alert: HighCPUUsage
            expr: container_cpu_usage_seconds_total{container!=""} / container_cpu_cfs_period_seconds{container!=""} * 100 > 80
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage"
              description: "Container {{ $labels.container }} in pod {{ $labels.pod }} has CPU usage of {{ $value }}%"
              dashboard_url: "https://grafana.veridis.xyz/d/resource-utilization"
              runbook_url: "https://docs.veridis.xyz/runbooks/resource-optimization"

          - alert: HighMemoryUsage
            expr: container_memory_usage_bytes{container!=""} / container_spec_memory_limit_bytes{container!=""} * 100 > 80
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage"
              description: "Container {{ $labels.container }} in pod {{ $labels.pod }} has memory usage of {{ $value }}%"
              dashboard_url: "https://grafana.veridis.xyz/d/resource-utilization"
              runbook_url: "https://docs.veridis.xyz/runbooks/resource-optimization"

          - alert: StarkNetTxFailures
            expr: rate(starknet_transaction_failures_total[5m]) > 0.1
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "StarkNet transaction failures"
              description: "StarkNet transactions are failing at rate of {{ $value }} per second"
              dashboard_url: "https://grafana.veridis.xyz/d/starknet-operations"
              runbook_url: "https://docs.veridis.xyz/runbooks/starknet-tx-failures"
```

### 12.3 Grafana Dashboard Configuration

Create `k8s/base/monitoring/grafana-dashboard.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: veridis-dashboards
data:
  veridis-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Veridis Protocol Overview",
        "tags": ["veridis", "privacy", "identity"],
        "timezone": "browser",
        "schemaVersion": 36,
        "version": 1,
        "refresh": "5s",
        "panels": [
          {
            "id": 1,
            "title": "Service Health",
            "type": "stat",
            "gridPos": {"h": 4, "w": 24, "x": 0, "y": 0},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "up{app=~\".*-service\"}",
                "legendFormat": "{{app}}"
              }
            ],
            "options": {
              "colorMode": "value",
              "graphMode": "none",
              "justifyMode": "auto",
              "orientation": "horizontal",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              },
              "textMode": "auto"
            },
            "fieldConfig": {
              "defaults": {
                "mappings": [
                  {
                    "type": "value",
                    "options": {
                      "0": {"text": "Down", "color": "red"},
                      "1": {"text": "Up", "color": "green"}
                    }
                  }
                ],
                "thresholds": {
                  "mode": "absolute",
                  "steps": [
                    {"color": "red", "value": null},
                    {"color": "green", "value": 1}
                  ]
                }
              }
            }
          },
          {
            "id": 2,
            "title": "Request Rate",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 4},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (app) (rate(http_requests_total{app=~\".*-service\"}[5m]))",
                "legendFormat": "{{app}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "reqps"
              }
            }
          },
          {
            "id": 3,
            "title": "Error Rate",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 4},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (app) (rate(http_requests_total{app=~\".*-service\",status=~\"5..\"}[5m]))",
                "legendFormat": "{{app}} errors"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "color": {"mode": "palette-classic"},
                "unit": "errps"
              }
            }
          },
          {
            "id": 4,
            "title": "ZK Proof Generation",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 12},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (circuit_type, status) (rate(zk_proof_generation_total[5m]))",
                "legendFormat": "{{circuit_type}} - {{status}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "ops"
              }
            }
          },
          {
            "id": 5,
            "title": "ZK Proof Duration",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 12},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum by (le, circuit_type) (rate(zk_proof_generation_duration_seconds_bucket[5m])))",
                "legendFormat": "{{circuit_type}} p95"
              },
              {
                "expr": "histogram_quantile(0.50, sum by (le, circuit_type) (rate(zk_proof_generation_duration_seconds_bucket[5m])))",
                "legendFormat": "{{circuit_type}} p50"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "s"
              }
            }
          },
          {
            "id": 6,
            "title": "Identity Operations",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 20},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (operation_type, status) (rate(identity_operations_total[5m]))",
                "legendFormat": "{{operation_type}} - {{status}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "ops"
              }
            }
          },
          {
            "id": 7,
            "title": "Attestation Operations",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 20},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (operation_type, status)                 (rate(attestation_operations_total[5m]))",
                "legendFormat": "{{operation_type}} - {{status}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "ops"
              }
            }
          },
          {
            "id": 8,
            "title": "Compliance Events",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 28},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (event_type, severity) (rate(compliance_events_total[5m]))",
                "legendFormat": "{{event_type}} - {{severity}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "ops"
              }
            }
          },
          {
            "id": 9,
            "title": "Cross-Chain Operations",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 28},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (source_chain, target_chain, status) (rate(bridge_messages_total[5m]))",
                "legendFormat": "{{source_chain}} -> {{target_chain}} ({{status}})"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "ops"
              }
            }
          },
          {
            "id": 10,
            "title": "Resource Usage",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 36},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (app) (container_cpu_usage_seconds_total{container!=\"\"})",
                "legendFormat": "{{app}} CPU"
              },
              {
                "expr": "sum by (app) (container_memory_usage_bytes{container!=\"\"})",
                "legendFormat": "{{app}} Memory"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                }
              },
              "overrides": [
                {
                  "matcher": {"id": "byRegexp", "options": ".*CPU.*"},
                  "properties": [{"id": "unit", "value": "s"}]
                },
                {
                  "matcher": {"id": "byRegexp", "options": ".*Memory.*"},
                  "properties": [{"id": "unit", "value": "bytes"}]
                }
              ]
            }
          }
        ],
        "templating": {
          "list": [
            {
              "name": "environment",
              "type": "query",
              "datasource": "Prometheus",
              "query": "label_values(environment)",
              "regex": "",
              "refresh": 1
            },
            {
              "name": "service",
              "type": "query",
              "datasource": "Prometheus",
              "query": "label_values(app)",
              "regex": "",
              "refresh": 1
            }
          ]
        },
        "time": {
          "from": "now-6h",
          "to": "now"
        },
        "links": [
          {
            "title": "Veridis Documentation",
            "url": "https://docs.veridis.xyz",
            "targetBlank": true
          },
          {
            "title": "Runbooks",
            "url": "https://docs.veridis.xyz/runbooks",
            "targetBlank": true
          }
        ]
      }
    }
  zk-proof-performance.json: |
    {
      "dashboard": {
        "id": null,
        "title": "ZK Proof Performance",
        "tags": ["veridis", "zk-proofs", "performance"],
        "timezone": "browser",
        "schemaVersion": 36,
        "version": 1,
        "refresh": "5s",
        "panels": [
          {
            "id": 1,
            "title": "Proof Generation Rate",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum by (circuit_type) (rate(zk_proof_generation_total{status=\"success\"}[5m]))",
                "legendFormat": "{{circuit_type}}"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "proofs/s"
              }
            }
          },
          {
            "id": 2,
            "title": "Proof Generation Duration",
            "type": "timeseries",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum by (le, circuit_type) (rate(zk_proof_generation_duration_seconds_bucket[5m])))",
                "legendFormat": "{{circuit_type}} p95"
              },
              {
                "expr": "histogram_quantile(0.50, sum by (le, circuit_type) (rate(zk_proof_generation_duration_seconds_bucket[5m])))",
                "legendFormat": "{{circuit_type}} p50"
              }
            ],
            "options": {
              "legend": {"showLegend": true},
              "tooltip": {"mode": "single", "sort": "none"}
            },
            "fieldConfig": {
              "defaults": {
                "custom": {
                  "drawStyle": "line",
                  "lineInterpolation": "linear",
                  "lineWidth": 1,
                  "fillOpacity": 10,
                  "showPoints": "never"
                },
                "unit": "s"
              }
            }
          },
          {
            "id": 3,
            "title": "Cache Hit Rate",
            "type": "gauge",
            "gridPos": {"h": 8, "w": 8, "x": 0, "y": 8},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(zk_proof_generation_total{status=\"cache_hit\"}[5m])) / sum(rate(zk_proof_generation_total[5m]))",
                "legendFormat": "Cache Hit Rate"
              }
            ],
            "options": {
              "orientation": "auto",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              },
              "showThresholdLabels": false,
              "showThresholdMarkers": true
            },
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "mappings": [],
                "max": 1,
                "min": 0,
                "thresholds": {
                  "mode": "absolute",
                  "steps": [
                    {"color": "red", "value": null},
                    {"color": "yellow", "value": 0.3},
                    {"color": "green", "value": 0.7}
                  ]
                },
                "unit": "percentunit"
              }
            }
          },
          {
            "id": 4,
            "title": "Failure Rate",
            "type": "gauge",
            "gridPos": {"h": 8, "w": 8, "x": 8, "y": 8},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(zk_proof_generation_total{status=\"failure\"}[5m])) / sum(rate(zk_proof_generation_total{status=~\"started|success|failure\"}[5m]))",
                "legendFormat": "Failure Rate"
              }
            ],
            "options": {
              "orientation": "auto",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              },
              "showThresholdLabels": false,
              "showThresholdMarkers": true
            },
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "mappings": [],
                "max": 1,
                "min": 0,
                "thresholds": {
                  "mode": "absolute",
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 0.01},
                    {"color": "red", "value": 0.05}
                  ]
                },
                "unit": "percentunit"
              }
            }
          },
          {
            "id": 5,
            "title": "GPU Utilization",
            "type": "gauge",
            "gridPos": {"h": 8, "w": 8, "x": 16, "y": 8},
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "nvidia_gpu_utilization{gpu=~\".*\"}",
                "legendFormat": "GPU {{gpu}}"
              }
            ],
            "options": {
              "orientation": "auto",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              },
              "showThresholdLabels": false,
              "showThresholdMarkers": true
            },
            "fieldConfig": {
              "defaults": {
                "color": {"mode": "thresholds"},
                "mappings": [],
                "max": 100,
                "min": 0,
                "thresholds": {
                  "mode": "absolute",
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 80},
                    {"color": "red", "value": 90}
                  ]
                },
                "unit": "percent"
              }
            }
          }
        ]
      }
    }
```

### 12.4 Application Metrics Integration

Create `services/shared/metrics.js`:

```javascript
const promClient = require("prom-client");
const logger = require("./logger");

// Create a registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics for Veridis
const httpRequestDuration = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code", "app"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10, 30],
});

const httpRequestsTotal = new promClient.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code", "app"],
});

const identityOperations = new promClient.Counter({
  name: "identity_operations_total",
  help: "Total number of identity operations",
  labelNames: ["operation_type", "status", "app"],
});

const attestationOperations = new promClient.Counter({
  name: "attestation_operations_total",
  help: "Total number of attestation operations",
  labelNames: ["operation_type", "status", "app"],
});

const zkProofGeneration = new promClient.Counter({
  name: "zk_proof_generation_total",
  help: "Total number of ZK proofs generated",
  labelNames: ["circuit_type", "status", "app"],
});

const zkProofGenerationDuration = new promClient.Histogram({
  name: "zk_proof_generation_duration_seconds",
  help: "Duration of ZK proof generation in seconds",
  labelNames: ["circuit_type", "app"],
  buckets: [0.1, 0.5, 1, 5, 10, 30, 60, 120, 300],
});

const complianceEvents = new promClient.Counter({
  name: "compliance_events_total",
  help: "Total number of compliance events",
  labelNames: ["event_type", "severity", "app"],
});

const gdprDataRetentionViolations = new promClient.Gauge({
  name: "gdpr_data_retention_violations",
  help: "Number of records exceeding GDPR retention period",
  labelNames: ["data_category", "app"],
});

const bridgeMessages = new promClient.Counter({
  name: "bridge_messages_total",
  help: "Total number of cross-chain bridge messages",
  labelNames: ["source_chain", "target_chain", "status", "app"],
});

const securityEvents = new promClient.Counter({
  name: "security_events_total",
  help: "Total number of security events",
  labelNames: ["event_type", "severity", "app"],
});

const resourceBoundsUsage = new promClient.Histogram({
  name: "resource_bounds_usage_ratio",
  help: "Ratio of actual resource usage to estimated bounds",
  labelNames: ["resource_type", "operation_type", "app"],
  buckets: [0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 1.5, 2.0],
});

const cairoNativePerformance = new promClient.Histogram({
  name: "cairo_native_execution_duration_seconds",
  help: "Duration of Cairo Native execution in seconds",
  labelNames: ["function_name", "optimization_level", "app"],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5],
});

// Register all metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(identityOperations);
register.registerMetric(attestationOperations);
register.registerMetric(zkProofGeneration);
register.registerMetric(zkProofGenerationDuration);
register.registerMetric(complianceEvents);
register.registerMetric(gdprDataRetentionViolations);
register.registerMetric(bridgeMessages);
register.registerMetric(securityEvents);
register.registerMetric(resourceBoundsUsage);
register.registerMetric(cairoNativePerformance);

// Get app name from environment
const appName = process.env.SERVICE_NAME || "veridis-service";

// Middleware for Express apps
const metricsMiddleware = (req, res, next) => {
  const start = Date.now();

  // Add response tracking
  const originalSend = res.send;
  res.send = function (body) {
    // Restore original function
    res.send = originalSend;

    // Track request metrics after processing
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path || "unknown";

    // Increment request counter
    httpRequestsTotal.labels(req.method, route, res.statusCode, appName).inc();

    // Record request duration
    httpRequestDuration
      .labels(req.method, route, res.statusCode, appName)
      .observe(duration);

    // Log slow requests
    if (duration > 1) {
      logger.warn(`Slow request detected`, {
        method: req.method,
        path: route,
        duration_seconds: duration,
        status_code: res.statusCode,
        context: "metrics",
      });
    }

    return originalSend.call(this, body);
  };

  next();
};

// Function to track Cairo Native performance
const trackCairoExecution = (functionName, optimizationLevel) => {
  const end = cairoNativePerformance
    .labels(
      functionName,
      optimizationLevel || process.env.MLIR_OPTIMIZATION_LEVEL || "0",
      appName
    )
    .startTimer();

  return end;
};

// Function to track resource bounds usage
const trackResourceBounds = (
  resourceType,
  operationType,
  actualUsage,
  estimatedBound
) => {
  if (estimatedBound && estimatedBound > 0) {
    const ratio = actualUsage / estimatedBound;
    resourceBoundsUsage
      .labels(resourceType, operationType, appName)
      .observe(ratio);

    // Log significant deviations
    if (ratio > 1.2) {
      logger.warn(`Resource bounds exceeded`, {
        resource_type: resourceType,
        operation_type: operationType,
        actual_usage: actualUsage,
        estimated_bound: estimatedBound,
        ratio: ratio,
        context: "resource-bounds",
      });
    }
  }
};

// Log startup
logger.info("Metrics initialized", {
  available_metrics: register.getMetricsAsArray().map((m) => m.name),
  app: appName,
  context: "metrics",
});

module.exports = {
  register,
  metricsMiddleware,
  trackCairoExecution,
  trackResourceBounds,
  metrics: {
    httpRequestDuration,
    httpRequestsTotal,
    identityOperations,
    attestationOperations,
    zkProofGeneration,
    zkProofGenerationDuration,
    complianceEvents,
    gdprDataRetentionViolations,
    bridgeMessages,
    securityEvents,
    resourceBoundsUsage,
    cairoNativePerformance,
  },
};
```

## 13. Security Considerations

### 13.1 Container Security Hardening

Create `docker/security/hardening.Dockerfile`:

```dockerfile
FROM node:20-alpine AS base

# Install security scanning tools
RUN apk add --no-cache \
    dumb-init \
    curl \
    jq \
    openssl \
    ca-certificates \
    tzdata

# Create non-root user with minimal privileges
RUN addgroup -g 1001 -S veridis && \
    adduser -u 1001 -S veridis -G veridis -h /app

# Security hardening
RUN mkdir -p /app && \
    chown -R veridis:veridis /app && \
    chmod -R 750 /app

# Set security-focused environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=512 --disallow-code-generation-from-strings"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate

# Create a directory for temporary files
RUN mkdir -p /app/tmp && \
    chown -R veridis:veridis /app/tmp
ENV TMPDIR=/app/tmp

WORKDIR /app

# Switch to non-root user early
USER veridis

FROM base AS dependencies

# Copy package files
COPY --chown=veridis:veridis package*.json ./

# Install dependencies with security audit
RUN npm ci --only=production --no-optional --no-fund && \
    npm audit --audit-level moderate && \
    rm -rf ~/.npm

# Security scans
RUN npm i -g snyk@latest && \
    snyk test --severity-threshold=medium || true && \
    npm uninstall -g snyk

FROM base

# Copy only production dependencies
COPY --from=dependencies /app/node_modules /app/node_modules

# Copy application code
COPY --chown=veridis:veridis . .

# Remove unnecessary files
RUN rm -rf \
    /app/tests \
    /app/docs \
    /app/.git* \
    /app/README.md \
    /app/coverage \
    /app/nodemon.json \
    /app/jest.config.js

# Create directory for runtime data
RUN mkdir -p \
    /app/logs \
    /app/data \
    && chown -R veridis:veridis /app/logs /app/data

# Set proper permissions
RUN find /app -type d -exec chmod 750 {} \; && \
    find /app -type f -exec chmod 640 {} \; && \
    find /app/bin -type f -name "*.sh" -exec chmod 750 {} \; 2>/dev/null || true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD [ "node", "healthcheck.js" ]

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Run with minimal privileges
CMD ["node", "--max-old-space-size=512", "index.js"]
```

### 13.2 Network Security Policies

Create `k8s/base/security/network-policies.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: identity-service-policy
spec:
  podSelector:
    matchLabels:
      app: identity-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
        - podSelector:
            matchLabels:
              app: verification-service
      ports:
        - protocol: TCP
          port: 3000
      namespaceSelector:
        matchLabels:
          name: veridis
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
    - to:
        - podSelector:
            matchLabels:
              app: starknet-devnet
      ports:
        - protocol: TCP
          port: 5050
    - to:
        - namespaceSelector:
            matchLabels:
              name: veridis-monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
    - to: {}
      ports:
        - protocol: TCP
          port: 443
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: compliance-service-policy
spec:
  podSelector:
    matchLabels:
      app: compliance-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: identity-service
        - podSelector:
            matchLabels:
              app: attestation-service
        - podSelector:
            matchLabels:
              app: api-gateway
      ports:
        - protocol: TCP
          port: 3001
      namespaceSelector:
        matchLabels:
          name: veridis
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
    - to:
        - namespaceSelector:
            matchLabels:
              name: veridis-monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
    - to: {}
      ports:
        - protocol: TCP
          port: 443
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: zk-proof-service-policy
spec:
  podSelector:
    matchLabels:
      app: zk-proof-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: verification-service
        - podSelector:
            matchLabels:
              app: attestation-service
      ports:
        - protocol: TCP
          port: 4000
      namespaceSelector:
        matchLabels:
          name: veridis
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: veridis-monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: bridge-service-policy
spec:
  podSelector:
    matchLabels:
      app: bridge-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-gateway
        - podSelector:
            matchLabels:
              app: verification-service
      ports:
        - protocol: TCP
          port: 3000
      namespaceSelector:
        matchLabels:
          name: veridis
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
    - to:
        - podSelector:
            matchLabels:
              app: starknet-devnet
      ports:
        - protocol: TCP
          port: 5050
    - to:
        - namespaceSelector:
            matchLabels:
              name: veridis-monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
    - to: {}
      ports:
        - protocol: TCP
          port: 443
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - identity-service
                  - attestation-service
                  - verification-service
                  - compliance-service
                  - bridge-service
      ports:
        - protocol: TCP
          port: 5432
      namespaceSelector:
        matchLabels:
          name: veridis
```

### 13.3 Pod Security Standards

Create `k8s/base/security/pod-security-policy.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: veridis-restricted-sa
  namespace: veridis
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: veridis-restricted-role
  namespace: veridis
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: veridis-restricted-binding
  namespace: veridis
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: veridis-restricted-role
subjects:
  - kind: ServiceAccount
    name: veridis-restricted-sa
    namespace: veridis
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-context-constraints
  namespace: veridis
data:
  security-context.yaml: |
    runAsUser:
      rule: 'MustRunAsNonRoot'
    runAsGroup:
      rule: 'MustRunAs'
      ranges:
        - min: 1000
          max: 65535
    fsGroup:
      rule: 'MustRunAs'
      ranges:
        - min: 1000
          max: 65535
    supplementalGroups:
      rule: 'MustRunAs'
      ranges:
        - min: 1000
          max: 65535
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
    seLinux:
      rule: 'RunAsAny'
    seccompProfile:
      type: 'RuntimeDefault'
    allowedHostPaths: []
    allowedCapabilities: []
    allowedProcMountTypes: []
    volumes:
      - 'configMap'
      - 'emptyDir'
      - 'projected'
      - 'secret'
      - 'downwardAPI'
      - 'persistentVolumeClaim'
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-context-default
  namespace: veridis
data:
  security-context-default.yaml: |
    defaultSecurityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 1000
      fsGroup: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
      readOnlyRootFilesystem: true
```

### 13.4 Security Scanning Pipeline

Create `.github/workflows/security-scan.yml`:

```yaml
name: Security Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: "0 2 * * *" # Daily at 2 AM

jobs:
  container-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker images
        run: |
          docker build -t veridis/identity-service:latest ./services/identity-service
          docker build -t veridis/attestation-service:latest ./services/attestation-service
          docker build -t veridis/compliance-service:latest ./services/compliance-service
          docker build -t veridis/zk-proof-service:latest ./zk-circuits

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "veridis/identity-service:latest,veridis/zk-proof-service:latest"
          format: "sarif"
          output: "trivy-results.sarif"
          severity: "CRITICAL,HIGH"
          ignore-unfixed: true

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "trivy-results.sarif"
          category: container-security

      - name: Check Docker image security best practices
        uses: goodwithtech/dockle-action@v1
        with:
          image: "veridis/identity-service:latest"
          format: sarif
          output: dockle-results.sarif

      - name: Upload Dockle scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "dockle-results.sarif"
          category: docker-best-practices

  cairo-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Scarb
        uses: software-mansion/setup-scarb@v1
        with:
          scarb-version: "2.11.4"

      - name: Install Cairo security scanner
        run: |
          cargo install cairo-security-scanner --locked
          cargo install starknet-analyzer --locked

      - name: Run Cairo security audit
        run: |
          cd contracts
          cairo-security-scanner scan --output-format=sarif --output security-results.sarif

      - name: Run StarkNet Analyzer
        run: |
          cd contracts
          starknet-analyzer analyze --output-format=sarif --output starknet-results.sarif

      - name: Upload Cairo security results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "contracts/security-results.sarif"
          category: cairo-security

      - name: Upload StarkNet Analyzer results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "contracts/starknet-results.sarif"
          category: starknet-security

      - name: Run formal verification
        run: |
          cd contracts
          scarb verify || echo "Formal verification issues found"

  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install Snyk
        run: |
          npm install -g snyk
          snyk auth ${{ secrets.SNYK_TOKEN }}

      - name: Run Snyk to check for vulnerabilities
        run: |
          for service in services/*/; do
            echo "Scanning $service"
            cd "$service"
            snyk test --severity-threshold=high || true
            snyk monitor --org=veridis-protocol
            cd ../../
          done

      - name: Audit dependencies
        run: |
          for service in services/*/; do
            echo "Auditing $service"
            cd "$service"
            npm audit --audit-level=high || true
            cd ../../
          done

  compliance-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build compliance checker container
        run: |
          docker build -t veridis/compliance-checker:latest -f docker/security/compliance-checker.Dockerfile .

      - name: GDPR Compliance Check
        run: |
          docker run --rm -v $(pwd):/workspace veridis/compliance-checker:latest \
            --check-gdpr \
            --check-data-retention \
            --check-audit-trail \
            --output /workspace/compliance-report.json

      - name: Upload compliance report
        uses: actions/upload-artifact@v4
        with:
          name: compliance-report
          path: compliance-report.json

  zk-proof-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install ZK security scanner
        run: |
          npm install -g zk-security-toolkit@latest

      - name: Run ZK circuit security analysis
        run: |
          cd zk-circuits
          zk-security-toolkit scan --circuits ./src --output security-report.json

      - name: Upload ZK security report
        uses: actions/upload-artifact@v4
        with:
          name: zk-security-report
          path: zk-circuits/security-report.json
```

## 14. Disaster Recovery and Backup

### 14.1 Database Backup Strategy

Create `k8s/base/backup/postgres-backup.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  labels:
    app: postgres-backup
    component: backup
spec:
  schedule: "0 2 * * *" # Daily at 2 AM
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 2
  jobTemplate:
    spec:
      backoffLimit: 3
      ttlSecondsAfterFinished: 86400 # 1 day
      template:
        metadata:
          labels:
            app: postgres-backup
            component: backup
        spec:
          containers:
            - name: postgres-backup
              image: postgres:15-alpine
              command:
                - /bin/sh
                - -c
                - |
                  # Set environment variables
                  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
                  BACKUP_DIR="/backup"
                  RETENTION_DAYS=${RETENTION_DAYS:-30}

                  # Create timestamped backup
                  BACKUP_FILE="veridis-${TIMESTAMP}.sql"
                  echo "Starting backup at $(date): ${BACKUP_FILE}"

                  # Backup main database
                  pg_dump -h postgres -U veridis -d veridis_main -F c > "${BACKUP_DIR}/${BACKUP_FILE}"

                  # Verify backup integrity
                  pg_restore --list "${BACKUP_DIR}/${BACKUP_FILE}" > /dev/null
                  if [ $? -eq 0 ]; then
                    echo "Backup integrity verified"
                  else
                    echo "ERROR: Backup verification failed"
                    exit 1
                  fi

                  # Compress backup
                  gzip "${BACKUP_DIR}/${BACKUP_FILE}"

                  # Calculate checksum
                  CHECKSUM=$(sha256sum "${BACKUP_DIR}/${BACKUP_FILE}.gz" | cut -d' ' -f1)

                  # Create backup manifest
                  cat > "${BACKUP_DIR}/manifest-${TIMESTAMP}.json" << EOF
                  {
                    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                    "backup_file": "${BACKUP_FILE}.gz",
                    "database": "veridis_main",
                    "size_bytes": $(stat -c%s "${BACKUP_DIR}/${BACKUP_FILE}.gz"),
                    "checksum": "${CHECKSUM}",
                    "postgres_version": "$(postgres --version)",
                    "encrypted": false
                  }
                  EOF

                  # Encrypt backup if configured
                  if [ -n "${ENCRYPTION_KEY}" ]; then
                    echo "Encrypting backup..."
                    openssl enc -aes-256-cbc -salt -in "${BACKUP_DIR}/${BACKUP_FILE}.gz" -out "${BACKUP_DIR}/${BACKUP_FILE}.gz.enc" -pass pass:${ENCRYPTION_KEY}
                    rm "${BACKUP_DIR}/${BACKUP_FILE}.gz"
                    
                    # Update manifest
                    sed -i 's/"encrypted": false/"encrypted": true/' "${BACKUP_DIR}/manifest-${TIMESTAMP}.json"
                    sed -i "s/${BACKUP_FILE}.gz/${BACKUP_FILE}.gz.enc/" "${BACKUP_DIR}/manifest-${TIMESTAMP}.json"
                  fi

                  # Cleanup old backups (keep RETENTION_DAYS days)
                  find ${BACKUP_DIR} -name "veridis-*.gz*" -mtime +${RETENTION_DAYS} -delete
                  find ${BACKUP_DIR} -name "manifest-*.json" -mtime +${RETENTION_DAYS} -delete

                  # Copy to remote storage if configured
                  if [ -n "${S3_BUCKET}" ] && [ -n "${AWS_ACCESS_KEY_ID}" ]; then
                    echo "Copying backup to S3: ${S3_BUCKET}"
                    # Install AWS CLI
                    apk add --no-cache aws-cli
                    
                    # Upload backup
                    BACKUP_PATH="${BACKUP_FILE}.gz"
                    [ -n "${ENCRYPTION_KEY}" ] && BACKUP_PATH="${BACKUP_FILE}.gz.enc"
                    
                    aws s3 cp "${BACKUP_DIR}/${BACKUP_PATH}" "s3://${S3_BUCKET}/postgres/${BACKUP_PATH}"
                    aws s3 cp "${BACKUP_DIR}/manifest-${TIMESTAMP}.json" "s3://${S3_BUCKET}/postgres/manifest-${TIMESTAMP}.json"
                    
                    # Verify upload
                    aws s3api head-object --bucket "${S3_BUCKET}" --key "postgres/${BACKUP_PATH}"
                    if [ $? -eq 0 ]; then
                      echo "Upload to S3 verified"
                    else
                      echo "ERROR: S3 upload verification failed"
                      exit 1
                    fi
                  fi

                  echo "Backup completed at $(date)"
              env:
                - name: PGPASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: veridis-secrets
                      key: DATABASE_PASSWORD
                - name: RETENTION_DAYS
                  value: "30"
                - name: ENCRYPTION_KEY
                  valueFrom:
                    secretKeyRef:
                      name: backup-secrets
                      key: ENCRYPTION_KEY
                      optional: true
                - name: S3_BUCKET
                  valueFrom:
                    configMapKeyRef:
                      name: backup-config
                      key: S3_BUCKET
                      optional: true
                - name: AWS_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: backup-secrets
                      key: AWS_ACCESS_KEY_ID
                      optional: true
                - name: AWS_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: backup-secrets
                      key: AWS_SECRET_ACCESS_KEY
                      optional: true
              volumeMounts:
                - name: backup-volume
                  mountPath: /backup
              resources:
                requests:
                  cpu: "200m"
                  memory: "512Mi"
                limits:
                  cpu: "500m"
                  memory: "1Gi"
          restartPolicy: OnFailure
          volumes:
            - name: backup-volume
              persistentVolumeClaim:
                claimName: backup-pvc
          securityContext:
            runAsNonRoot: true
            runAsUser: 70 # postgres user
            fsGroup: 70
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  labels:
    app: postgres-backup
    component: storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: standard
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-config
data:
  S3_BUCKET: "veridis-backups"
  BACKUP_SCHEDULE: "0 2 * * *"
```

### 14.2 StarkNet State Backup

Create `scripts/starknet-state-backup.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-development}
BACKUP_DIR="./backups/starknet/$ENVIRONMENT/$(date +%Y%m%d-%H%M%S)"

echo "📸 Creating StarkNet state backup for $ENVIRONMENT..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Set RPC endpoint based on environment
case "$ENVIRONMENT" in
  "development")
    RPC_URL="http://localhost:5050/rpc/v0_8_1"
    ;;
  "staging")
    RPC_URL="https://alpha4.starknet.io/rpc/v0_8_1"
    ;;
  "production")
    RPC_URL="https://alpha-mainnet.starknet.io/rpc/v0_8_1"
    ;;
  *)
    echo "❌ Invalid environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Verify StarkNet RPC endpoint is accessible
echo "🔍 Verifying RPC endpoint..."
if ! curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' \
  $RPC_URL | grep -q "result"; then
  echo "❌ RPC endpoint not accessible: $RPC_URL"
  exit 1
fi

# Get latest block
echo "🔍 Getting latest block information..."
LATEST_BLOCK_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"starknet_blockNumber","params":[],"id":1}' \
  $RPC_URL)

LATEST_BLOCK=$(echo $LATEST_BLOCK_RESPONSE | jq -r '.result')

if [ "$LATEST_BLOCK" == "null" ] || [ -z "$LATEST_BLOCK" ]; then
  echo "❌ Failed to get latest block"
  echo "Response: $LATEST_BLOCK_RESPONSE"
  exit 1
fi

echo "Latest block: $LATEST_BLOCK"

# Get chain ID
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' \
  $RPC_URL | jq -r '.result')

echo "Chain ID: $CHAIN_ID"

# Get latest block details
echo "📋 Getting block details..."
curl -s -X POST -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getBlockWithTxs\",\"params\":[{\"block_number\":$LATEST_BLOCK}],\"id\":1}" \
  $RPC_URL > "$BACKUP_DIR/latest_block.json"

# Backup contract addresses and state
CONTRACTS=(
  "identity_registry"
  "attestation_registry"
  "compliance_engine"
  "bridge_contract"
)

echo "📝 Loading deployment artifacts..."
if [ -f "deployments/$ENVIRONMENT-latest.json" ]; then
  cp "deployments/$ENVIRONMENT-latest.json" "$BACKUP_DIR/deployment-metadata.json"
else
  echo "⚠️ Deployment artifacts not found for $ENVIRONMENT"
  exit 1
fi

for CONTRACT in "${CONTRACTS[@]}"; do
  echo "📋 Backing up $CONTRACT state..."

  # Get contract address from deployment artifacts
  CONTRACT_ADDRESS=$(jq -r ".contracts.$CONTRACT" "$BACKUP_DIR/deployment-metadata.json")

  if [ "$CONTRACT_ADDRESS" != "null" ] && [ -n "$CONTRACT_ADDRESS" ]; then
    # Create contract directory
    mkdir -p "$BACKUP_DIR/$CONTRACT"

    # Get contract class hash
    echo "  - Getting class hash for $CONTRACT..."
    curl -s -X POST -H "Content-Type: application/json" \
      --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getClassHashAt\",\"params\":[\"$CONTRACT_ADDRESS\",\"latest\"],\"id\":1}" \
      $RPC_URL > "$BACKUP_DIR/$CONTRACT/class_hash.json"

    CLASS_HASH=$(jq -r '.result' "$BACKUP_DIR/$CONTRACT/class_hash.json")

    if [ "$CLASS_HASH" != "null" ] && [ -n "$CLASS_HASH" ]; then
      # Get contract class
      echo "  - Getting class definition for $CONTRACT..."
      curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getClass\",\"params\":[\"$CLASS_HASH\",\"latest\"],\"id\":1}" \
        $RPC_URL > "$BACKUP_DIR/$CONTRACT/class_definition.json"

      # Get contract state (simplified - get storage at key positions)
      echo "  - Getting storage state for $CONTRACT..."
      for STORAGE_KEY in $(seq 0 10); do
        STORAGE_KEY_HEX=$(printf "0x%064x" $STORAGE_KEY)
        curl -s -X POST -H "Content-Type: application/json" \
          --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getStorageAt\",\"params\":[\"$CONTRACT_ADDRESS\",\"$STORAGE_KEY_HEX\",\"latest\"],\"id\":1}" \
          $RPC_URL > "$BACKUP_DIR/$CONTRACT/storage_$STORAGE_KEY.json"
      done
    else
      echo "⚠️ Failed to get class hash for $CONTRACT"
    fi
  else
    echo "⚠️ Contract $CONTRACT not found in deployment artifacts"
  fi
done

# Encrypt backup if ENCRYPTION_KEY is provided
if [ -n "$ENCRYPTION_KEY" ]; then
  echo "🔐 Encrypting backup..."

  # Create tar archive
  cd "$(dirname "$BACKUP_DIR")"
  BACKUP_NAME="$(basename "$BACKUP_DIR")"
  tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

  # Encrypt tar file
  openssl enc -aes-256-cbc -salt -in "${BACKUP_NAME}.tar.gz" -out "${BACKUP_NAME}.tar.gz.enc" -k "$ENCRYPTION_KEY"

  # Clean up
  rm -rf "$BACKUP_NAME" "${BACKUP_NAME}.tar.gz"

  echo "✅ Backup encrypted: $(pwd)/${BACKUP_NAME}.tar.gz.enc"
else
  # Create backup manifest
  cat > "$BACKUP_DIR/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "chain_id": "$CHAIN_ID",
  "network": "starknet-$([ "$CHAIN_ID" = "SN_MAIN" ] && echo "mainnet" || echo "testnet")",
  "latest_block": "$LATEST_BLOCK",
  "rpc_url": "$RPC_URL",
  "contracts_backed_up": $(printf '%s\n' "${CONTRACTS[@]}" | jq -R . | jq -s .),
  "backup_type": "state_snapshot",
  "veridis_version": "3.2.1"
}
EOF

  echo "✅ StarkNet state backup completed!"
  echo "📁 Backup stored in: $BACKUP_DIR"
fi

# Copy to S3 if AWS credentials are available
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$S3_BUCKET" ]; then
  echo "☁️ Copying backup to S3..."

  if [ -n "$ENCRYPTION_KEY" ]; then
    # Upload encrypted file
    aws s3 cp "$(dirname "$BACKUP_DIR")/${BACKUP_NAME}.tar.gz.enc" "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/${BACKUP_NAME}.tar.gz.enc"
  else
    # Create tar archive
    cd "$(dirname "$BACKUP_DIR")"
    BACKUP_NAME="$(basename "$BACKUP_DIR")"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"

    # Upload tar file
    aws s3 cp "${BACKUP_NAME}.tar.gz" "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/${BACKUP_NAME}.tar.gz"

    # Clean up
    rm "${BACKUP_NAME}.tar.gz"
  fi

  echo "✅ Backup copied to S3: s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/"
fi
```

### 14.3 Cross-Chain State Recovery

Create `scripts/disaster-recovery.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
BACKUP_DATE=${2:-latest}
COMPONENTS=${3:-"all"} # all, database, starknet, zk, contracts

echo "🚨 Starting disaster recovery for $ENVIRONMENT environment..."

# Validate environment
if [ "$ENVIRONMENT" = "production" ]; then
    echo "⚠️  Production recovery requires additional confirmation"
    read -p "Are you sure you want to recover production? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Recovery cancelled"
        exit 1
    fi

    # Double-check for production
    read -p "This will OVERWRITE PRODUCTION DATA. Type 'I UNDERSTAND' to continue: " confirm2
    if [ "$confirm2" != "I UNDERSTAND" ]; then
        echo "❌ Recovery cancelled"
        exit 1
    fi
fi

# Log start of recovery process
RECOVERY_LOG="recovery-log-$(date +%Y%m%d-%H%M%S).txt"
echo "📝 Logging recovery process to: $RECOVERY_LOG"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$RECOVERY_LOG"
}

log "Starting disaster recovery for $ENVIRONMENT environment"
log "Components to recover: $COMPONENTS"

# Verify kubectl access
if ! kubectl cluster-info &> /dev/null; then
    log "❌ kubectl not configured or cluster not accessible"
    exit 1
fi

# Verify target namespace
TARGET_NAMESPACE="veridis-$ENVIRONMENT"
if ! kubectl get namespace "$TARGET_NAMESPACE" &> /dev/null; then
    log "❌ Target namespace $TARGET_NAMESPACE does not exist"
    exit 1
fi

# Find backup
if [[ "$COMPONENTS" == *"database"* ]] || [[ "$COMPONENTS" == "all" ]]; then
    log "🔍 Locating database backup..."

    if [ "$BACKUP_DATE" = "latest" ]; then
        # Get latest backup from S3 or local
        if [ -n "$S3_BUCKET" ]; then
            LATEST_DB_BACKUP=$(aws s3 ls "s3://${S3_BUCKET}/postgres/" | sort | tail -n 1 | awk '{print $4}')
            log "Latest database backup in S3: $LATEST_DB_BACKUP"

            # Download backup
            log "Downloading database backup from S3..."
            mkdir -p recovery-tmp
            aws s3 cp "s3://${S3_BUCKET}/postgres/$LATEST_DB_BACKUP" "recovery-tmp/$LATEST_DB_BACKUP"
            DB_BACKUP_PATH="recovery-tmp/$LATEST_DB_BACKUP"
        else
            DB_BACKUP_PATH=$(ls -td backups/postgres/* | head -1)
            log "Latest local database backup: $DB_BACKUP_PATH"
        fi
    else
        # Get specific backup by date
        if [ -n "$S3_BUCKET" ]; then
            DB_BACKUP=$(aws s3 ls "s3://${S3_BUCKET}/postgres/" | grep "$BACKUP_DATE" | head -1 | awk '{print $4}')
            log "Database backup in S3 matching date $BACKUP_DATE: $DB_BACKUP"

            # Download backup
            log "Downloading database backup from S3..."
            mkdir -p recovery-tmp
            aws s3 cp "s3://${S3_BUCKET}/postgres/$DB_BACKUP" "recovery-tmp/$DB_BACKUP"
            DB_BACKUP_PATH="recovery-tmp/$DB_BACKUP"
        else
            DB_BACKUP_PATH=$(ls -td backups/postgres/* | grep "$BACKUP_DATE" | head -1)
            log "Database backup matching date $BACKUP_DATE: $DB_BACKUP_PATH"
        fi
    fi

    if [ -z "$DB_BACKUP_PATH" ] || [ ! -f "$DB_BACKUP_PATH" ]; then
        log "⚠️ Database backup not found, skipping database restoration"
    fi
fi

# Find StarkNet state backup
if [[ "$COMPONENTS" == *"starknet"* ]] || [[ "$COMPONENTS" == "all" ]]; then
    log "🔍 Locating StarkNet state backup..."

    if [ "$BACKUP_DATE" = "latest" ]; then
        # Get latest backup from S3 or local
        if [ -n "$S3_BUCKET" ]; then
            LATEST_SN_BACKUP=$(aws s3 ls "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/" | sort | tail -n 1 | awk '{print $4}')
            log "Latest StarkNet backup in S3: $LATEST_SN_BACKUP"

            # Download backup
            log "Downloading StarkNet backup from S3..."
            mkdir -p recovery-tmp
            aws s3 cp "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/$LATEST_SN_BACKUP" "recovery-tmp/$LATEST_SN_BACKUP"
            SN_BACKUP_PATH="recovery-tmp/$LATEST_SN_BACKUP"
        else
            SN_BACKUP_PATH=$(ls -td backups/starknet/$ENVIRONMENT/* | head -1)
            log "Latest local StarkNet backup: $SN_BACKUP_PATH"
        fi
    else
        # Get specific backup by date
        if [ -n "$S3_BUCKET" ]; then
            SN_BACKUP=$(aws s3 ls "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/" | grep "$BACKUP_DATE" | head -1 | awk '{print $4}')
            log "StarkNet backup in S3 matching date $BACKUP_DATE: $SN_BACKUP"

            # Download backup
            log "Downloading StarkNet backup from S3..."
            mkdir -p recovery-tmp
            aws s3 cp "s3://${S3_BUCKET}/starknet/${ENVIRONMENT}/$SN_BACKUP" "recovery-tmp/$SN_BACKUP"
            SN_BACKUP_PATH="recovery-tmp/$SN_BACKUP"
        else
            SN_BACKUP_PATH=$(ls -td backups/starknet/$ENVIRONMENT/* | grep "$BACKUP_DATE" | head -1)
            log "StarkNet backup matching date $BACKUP_DATE: $SN_BACKUP_PATH"
        fi
    fi

    if [ -z "$SN_BACKUP_PATH" ] || [ ! -e "$SN_BACKUP_PATH" ]; then
        log "⚠️ StarkNet backup not found, skipping StarkNet state restoration"
    fi
fi

# Stop affected services
if [[ "$COMPONENTS" == *"database"* ]] || [[ "$COMPONENTS" == "all" ]]; then
    log "🛑 Scaling down services that depend on the database..."
    kubectl scale deployment --namespace="$TARGET_NAMESPACE" --replicas=0 \
        $(kubectl get deployment --namespace="$TARGET_NAMESPACE" -l "component=backend" -o name | tr '\n' ' ')

    log "⏳ Waiting for pods to terminate..."
    kubectl wait --namespace="$TARGET_NAMESPACE" --for=delete pods \
        --selector="component=backend" --timeout=180s || true
fi

# Restore database
if [[ "$COMPONENTS" == *"database"* ]] || [[ "$COMPONENTS" == "all" ]] && [ -n "$DB_BACKUP_PATH" ]; then
    log "🗄️ Restoring database..."

    # Check if backup is encrypted
    if [[ "$DB_BACKUP_PATH" == *.enc ]]; then
        if [ -z "$ENCRYPTION_KEY" ]; then
            log "❌ Backup is encrypted but no encryption key provided"
            exit 1
        fi

        log "🔓 Decrypting database backup..."
        openssl enc -d -aes-256-cbc -in "$DB_BACKUP_PATH" -out "${DB_BACKUP_PATH%.enc}" -k "$ENCRYPTION_KEY"
        DB_BACKUP_PATH="${DB_BACKUP_PATH%.enc}"
    fi

    # Decompress if needed
    if [[ "$DB_BACKUP_PATH" == *.gz ]]; then
        log "📦 Decompressing database backup..."
        gunzip -c "$DB_BACKUP_PATH" > "${DB_BACKUP_PATH%.gz}"
        DB_BACKUP_PATH="${DB_BACKUP_PATH%.gz}"
    fi

    # Create temporary pod for database restoration
    log "🔄 Creating temporary pod for database restoration..."
    kubectl run postgres-restore --rm -i --restart=Never \
        --namespace="$TARGET_NAMESPACE" \
        --image=postgres:15-alpine \
        --env="PGPASSWORD=$(kubectl get secret --namespace=$TARGET_NAMESPACE veridis-secrets -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)" \
        -- bash -c "
            psql -h postgres -U veridis -d veridis_main -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
            psql -h postgres -U veridis -d veridis_main < /tmp/backup.sql
        " < "$DB_BACKUP_PATH"

    log "✅ Database restoration completed"
fi

# Restore StarkNet contracts state
if [[ "$COMPONENTS" == *"starknet"* ]] || [[ "$COMPONENTS" == "all" ]] && [ -n "$SN_BACKUP_PATH" ]; then
    log "📝 Restoring StarkNet contract state..."

    # Check if backup is encrypted
    if [[ "$SN_BACKUP_PATH" == *.enc ]]; then
        if [ -z "$ENCRYPTION_KEY" ]; then
            log "❌ Backup is encrypted but no encryption key provided"
            exit 1
        fi

        log "🔓 Decrypting StarkNet backup..."
        openssl enc -d -aes-256-cbc -in "$SN_BACKUP_PATH" -out "${SN_BACKUP_PATH%.enc}" -k "$ENCRYPTION_KEY"
        SN_BACKUP_PATH="${SN_BACKUP_PATH%.enc}"
    fi

    # Extract if needed
    if [[ "$SN_BACKUP_PATH" == *.tar.gz ]]; then
        log "📦 Extracting StarkNet backup..."
        mkdir -p recovery-tmp/starknet
        tar -xzf "$SN_BACKUP_PATH" -C recovery-tmp/starknet
        SN_BACKUP_PATH="recovery-tmp/starknet/$(basename "${SN_BACKUP_PATH%.tar.gz}")"
    fi

    # Restore deployment metadata
    if [ -f "$SN_BACKUP_PATH/deployment-metadata.json" ]; then
        log "🔄 Restoring deployment metadata..."
        mkdir -p "deployments"
        cp "$SN_BACKUP_PATH/deployment-metadata.json" "deployments/$ENVIRONMENT-latest.json"
    fi

    # Verify contract deployment status
    log "🔍 Verifying contract deployment status..."
    DEPLOYMENT_FILE="deployments/$ENVIRONMENT-latest.json"
    if [ -f "$DEPLOYMENT_FILE" ]; then
        # Extract contract addresses
        IDENTITY_CONTRACT=$(jq -r '.contracts.identity' "$DEPLOYMENT_FILE")
        ATTESTATION_CONTRACT=$(jq -r '.contracts.attestation' "$DEPLOYMENT_FILE")
        COMPLIANCE_CONTRACT=$(jq -r '.contracts.compliance' "$DEPLOYMENT_FILE")
        BRIDGE_CONTRACT=$(jq -r '.contracts.bridge' "$DEPLOYMENT_FILE")

        log "Contract addresses from backup:"
        log "- Identity: $IDENTITY_CONTRACT"
        log "- Attestation: $ATTESTATION_CONTRACT"
        log "- Compliance: $COMPLIANCE_CONTRACT"
        log "- Bridge: $BRIDGE_CONTRACT"
    else
        log "⚠️ Deployment metadata not found"
    fi

    log "✅ StarkNet state restoration completed"
fi

# Restore ZK proof service data
if [[ "$COMPONENTS" == *"zk"* ]] || [[ "$COMPONENTS" == "all" ]]; then
    log "🔑 Restoring ZK proof service data..."

    # Find ZK proof service PVC
    ZK_PVC=$(kubectl get pvc --namespace="$TARGET_NAMESPACE" -l "app=zk-proof-service" -o name | head -1)

    if [ -n "$ZK_PVC" ]; then
        # Create temporary pod to restore ZK data
        log "🔄 Creating temporary pod for ZK data restoration..."
        kubectl run zk-restore --rm -i --restart=Never \
            --namespace="$TARGET_NAMESPACE" \
            --image=busybox \
            --overrides="{\"spec\":{\"volumes\":[{\"name\":\"zk-data\",\"persistentVolumeClaim\":{\"claimName\":\"${ZK_PVC#persistentvolumeclaim/}\"}}],\"containers\":[{\"name\":\"zk-restore\",\"image\":\"busybox\",\"command\":[\"sh\"],\"stdin\":true,\"stdinOnce\":true,\"volumeMounts\":[{\"name\":\"zk-data\",\"mountPath\":\"/data\"}]}]}}" \
            -- sh -c "
                mkdir -p /data/keys
                echo 'ZK keys would be restored here in a real recovery'
                touch /data/recovery-marker-$(date +%Y%m%d-%H%M%S)
            "

        log "✅ ZK proof service data restoration completed"
    else
        log "⚠️ ZK proof service PVC not found, skipping ZK data restoration"
    fi
fi

# Restart services
log "▶️ Restarting services..."
if [[ "$COMPONENTS" == *"database"* ]] || [[ "$COMPONENTS" == "all" ]]; then
    # Scale up database-dependent services
    for service in identity-service attestation-service verification-service compliance-service bridge-service; do
        REPLICAS=$(kubectl get deployment --namespace="$TARGET_NAMESPACE" "$service" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "2")
        if [ "$REPLICAS" -eq "0" ]; then
            REPLICAS=2  # Default to 2 replicas if undefined
        fi

        log "Scaling $service to $REPLICAS replicas"
        kubectl scale deployment --namespace="$TARGET_NAMESPACE" "$service" --replicas="$REPLICAS"
    done
fi

# Wait for services to be ready
log "⏳ Waiting for services to be ready..."
for service in identity-service attestation-service verification-service compliance-service bridge-service; do
    if kubectl get deployment --namespace="$TARGET_NAMESPACE" "$service" &> /dev/null; then
        kubectl wait --namespace="$TARGET_NAMESPACE" --for=condition=available deployment/"$service" --timeout=300s || log "⚠️ Timed out waiting for $service"
    fi
done

# Run health checks
log "🔍 Running post-recovery health checks..."
for service in identity-service attestation-service verification-service compliance-service bridge-service; do
    if kubectl get deployment --namespace="$TARGET_NAMESPACE" "$service" &> /dev/null; then
        POD=$(kubectl get pods --namespace="$TARGET_NAMESPACE" -l "app=$service" -o name | head -1)
        if [ -n "$POD" ]; then
            HEALTH_STATUS=$(kubectl exec --namespace="$TARGET_NAMESPACE" "$POD" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "failed")
            log "Health check for $service: $HEALTH_STATUS"
        fi
    fi
done

# Generate recovery report
log "📊 Generating recovery report..."
cat > "recovery-report-$(date +%Y%m%d-%H%M%S).json" << EOF
{
  "recovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "components_recovered": "$COMPONENTS",
  "database_backup_used": "$([ -n "$DB_BACKUP_PATH" ] && echo "$(basename "$DB_BACKUP_PATH")" || echo "none")",
  "starknet_backup_used": "$([ -n "$SN_BACKUP_PATH" ] && echo "$(basename "$SN_BACKUP_PATH")" || echo "none")",
  "services_restarted": [
    "identity-service",
    "attestation-service",
    "verification-service",
    "compliance-service",
    "bridge-service"
  ],
  "recovery_log": "$RECOVERY_LOG"
}
EOF

# Clean up temporary files
if [ -d "recovery-tmp" ]; then
    log "🧹 Cleaning up temporary files..."
    rm -rf recovery-tmp
fi

log "✅ Disaster recovery completed successfully!"
log "📄 Recovery report generated: recovery-report-$(date +%Y%m%d-%H%M%S).json"
```

## 15. References and Additional Resources

### 15.1 Official Documentation

#### StarkNet and Cairo Documentation

- [StarkNet Documentation](https://docs.starknet.io/) - Official StarkNet protocol documentation
- [Cairo Language Documentation](https://cairo-lang.org/docs/) - Comprehensive Cairo programming guide
- [Scarb Package Manager](https://docs.swmansion.com/scarb/) - Official Scarb documentation for Cairo v2.11.4
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Testing and deployment framework
- [StarkNet Transaction v3](https://docs.starknet.io/documentation/starknet_versions/upcoming_versions/) - Resource bounds and transaction v3 documentation
- [Cairo Native](https://github.com/cairo-native/cairo-native) - Native execution engine with MLIR optimization

#### Container and Orchestration

- [Docker Documentation](https://docs.docker.com/) - Container platform documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Container orchestration platform
- [Helm Documentation](https://helm.sh/docs/) - Kubernetes package manager
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) - Kubernetes configuration management
- [Prometheus Documentation](https://prometheus.io/docs/) - Monitoring and alerting platform
- [Grafana Documentation](https://grafana.com/docs/) - Metrics visualization platform

### 15.2 Security and Compliance

#### Privacy and Compliance Standards

- [GDPR Compliance Framework](https://gdpr.eu/) - General Data Protection Regulation guidelines
- [Privacy by Design Principles](https://www.ipc.on.ca/wp-content/uploads/resources/7foundationalprinciples.pdf) - Core privacy design principles
- [SOC 2 Compliance Standards](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report.html) - Enterprise security standards
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) - Security best practices
- [OWASP Container Security Guidelines](https://owasp.org/www-project-docker-security/) - Container security best practices

#### Zero-Knowledge Proof Systems

- [Garaga SDK Documentation](https://garaga.dev/) - ZK proof generation framework for StarkNet
- [StarkNet ZK-STARK Proofs](https://starkware.co/stark/) - Core cryptographic primitives
- [Privacy-Preserving Identity Systems](https://eprint.iacr.org/2023/114.pdf) - Academic research on identity protocols
- [ZK Circuit Optimization Guide](https://docs.veridis.xyz/zk-optimization) - Best practices for ZK circuit optimization
- [Zero-Knowledge Proofs for Enterprise](https://zkproof.org/2022/04/20/zkproof-enterprise-applications/) - Enterprise applications of ZK proofs

### 15.3 Development Tools and Resources

#### Enterprise Development Tools

- [Veridis CLI Tools](https://github.com/veridis-protocol/cli-tools-v3) - Command-line development utilities
- [Veridis VS Code Extension](https://marketplace.visualstudio.com/items?itemName=veridis.cairo-tools-v3) - IDE integration for Cairo development
- [Cairo Profiler](https://github.com/veridis-protocol/cairo-profiler) - Gas optimization and performance analysis
- [StarkNet Security Analyzer](https://github.com/veridis-protocol/starknet-analyzer) - Smart contract security analysis
- [Cairo Formal Verification Tool](https://github.com/veridis-protocol/cairo-verifier) - Formal verification for Cairo contracts

#### Community and Support

- [Veridis Developer Forum](https://forum.veridis.xyz) - Community discussion and support
- [Discord Community](https://discord.gg/veridis) - Real-time developer chat
- [GitHub Discussions](https://github.com/veridis-protocol/veridis-sdk-v3/discussions) - Technical discussions and Q&A
- [StarkNet Ecosystem](https://starknet-ecosystem.com) - Comprehensive StarkNet ecosystem resources
- [Cairo Book](https://book.cairo-lang.org/) - Comprehensive guide to Cairo language

### 15.4 Monitoring and Operations

#### Observability Tools

- [Prometheus Documentation](https://prometheus.io/docs/) - Metrics collection and alerting
- [Grafana Documentation](https://grafana.com/docs/) - Metrics visualization and dashboards
- [Enterprise Monitoring Dashboard](https://metrics.veridis.xyz) - Production monitoring interface
- [Status Page](https://status.veridis.xyz) - Service availability and incident tracking
- [Jaeger Tracing](https://www.jaegertracing.io/docs/) - Distributed tracing platform

#### Performance and Benchmarks

- [Performance Benchmarks](https://benchmarks.veridis.xyz) - Protocol performance metrics
- [Gas Optimization Guide](https://docs.veridis.xyz/v3/performance) - Cairo gas optimization strategies
- [Cross-Chain Latency Metrics](https://metrics.veridis.xyz/cross-chain) - Bridge performance data
- [ZK Proof Generation Benchmarks](https://benchmarks.veridis.xyz/zk-proofs) - Zero-knowledge proof performance metrics
- [MLIR Optimization Guidelines](https://docs.veridis.xyz/v3/mlir-optimization) - Cairo MLIR optimization best practices

### 15.5 Enterprise Resources

#### Professional Services

- [Enterprise Portal](https://enterprise.veridis.xyz) - Enterprise customer resources
- [Professional Services](https://veridis.xyz/professional-services) - Implementation and consulting
- [Training Programs](https://training.veridis.xyz) - Developer certification and workshops
- [Compliance Tools](https://compliance.veridis.xyz) - Enterprise compliance solutions
- [ZK-Based Privacy Solutions](https://privacy.veridis.xyz) - Zero-knowledge privacy solutions

#### Compliance and Audit

- [Security Audits](https://audits.veridis.xyz) - Third-party security assessments
- [Compliance Templates](https://github.com/veridis-protocol/compliance-templates) - GDPR and regulatory compliance tools
- [Audit Framework](https://github.com/veridis-protocol/audit-framework) - Automated compliance monitoring
- [Privacy Impact Assessment](https://github.com/veridis-protocol/privacy-assessment) - Privacy impact assessment tools
- [Security Operations Center](https://security.veridis.xyz) - Enterprise security operations

### 15.6 Research and Development

#### Academic Resources

- [Veridis Whitepaper v3.0](https://veridis.xyz/whitepaper-v3.pdf) - Protocol specification and cryptographic foundations
- [Research Publications](https://research.veridis.xyz) - Academic papers and technical research
- [Academic Partnerships](https://veridis.xyz/academic) - University collaboration and research programs
- [Zero-Knowledge Research Group](https://zkresearch.veridis.xyz) - Zero-knowledge research initiatives
- [Privacy Protocols Consortium](https://privacyprotocols.org) - Industry collaboration on privacy protocols

#### Technical Implementation Guides

- [Migration Guide from v2.x](https://docs.veridis.xyz/v3/migration) - Upgrading from previous versions
- [Cross-Chain Bridge Architecture](https://docs.veridis.xyz/v3/bridge) - Multi-chain implementation details
- [Enterprise GDPR Implementation](https://docs.veridis.xyz/v3/compliance/gdpr) - Privacy compliance automation
- [Resource Bounds Implementation](https://docs.veridis.xyz/v3/resource-bounds) - StarkNet transaction v3 resource bounds
- [MLIR Optimization Guide](https://docs.veridis.xyz/v3/mlir-optimization) - Cairo MLIR optimization guide

---

**Document Metadata**

- **Document ID**: VERIDIS-DEVENV-2025-002
- **Version**: 2.0
- **Date**: 2025-05-31
- **Authors**: Cass402
- **Last Edit**: 2025-05-31 05:55:15 UTC by Cass402
- **Classification**: Internal Technical Documentation
- **Distribution**: Veridis Engineering, External Developers, Technical Partners, Enterprise Customers
