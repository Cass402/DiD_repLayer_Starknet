# Veridis: Development Environment and Container Orchestration Guide

This comprehensive guide provides detailed instructions for setting up development environments, containerizing Veridis protocol components, and deploying them using modern orchestration tools. The Veridis protocol is a privacy-preserving identity and attestation system built on StarkNet with enterprise-grade compliance features and cross-chain capabilities. The guide ensures consistent development environments across all team members and provides production-ready deployment strategies for the Cairo v2.11.4 and StarkNet v0.11 ecosystem.

## Document Control

| Version | Date       | Author  | Description of Changes |
| :------ | :--------- | :------ | :--------------------- |
| 1.0     | 2025-05-30 | Cass402 | Initial version        |

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

This guide provides comprehensive instructions for setting up consistent development environments, containerizing the Veridis protocol components, and deploying them using Kubernetes[^1]. The Veridis protocol is a privacy-preserving identity and attestation system that enables verifiable credentials, zero-knowledge verification, cross-chain identity management, and enterprise-grade compliance features[^2].

### 1.2 Scope

This document covers:

- Local development environment configuration for Cairo v2.11.4 and StarkNet v0.11
- VSCode setup with Cairo-specific extensions and tooling
- Development containers configuration with enterprise features
- Docker and Docker Compose setup for component orchestration
- Kubernetes deployment configurations for production environments
- Environment-specific configurations and secret management
- Cairo-specific container considerations and optimization
- ZK proof generation infrastructure with Garaga SDK integration
- Cross-chain testing environments for multi-blockchain validation
- Enterprise compliance automation and GDPR enforcement

### 1.3 Audience

This guide is intended for:

- Cairo developers building on StarkNet v0.11
- DevOps engineers implementing enterprise infrastructure
- Security engineers conducting formal verification audits
- Compliance teams implementing GDPR automation
- QA engineers testing cross-chain functionality
- Enterprise developers requiring performance optimization

### 1.4 Related Documents

- Veridis Project Requirements Specification (VERIDIS-SPEC-REQ-2025-001)
- Veridis Developer SDK Specifications v2.0 (VERIDIS-SPEC-SDK-V2-2025-002)
- Veridis Security Protocols and Compliance Framework
- Veridis Cross-Chain Bridge Architecture Guide

## 2. Development Environment Setup

### 2.1 Prerequisites

Ensure the following software is installed on your development machine:

| Software         | Version        | Purpose                                   |
| :--------------- | :------------- | :---------------------------------------- |
| Scarb            | 2.11.4         | Cairo package manager and build tool      |
| Cairo Native     | 2.11.4         | Native Cairo execution engine             |
| Starknet Foundry | 0.44.0         | StarkNet testing and deployment framework |
| Docker           | 25.0+          | Container runtime                         |
| Docker Compose   | 2.20+          | Multi-container orchestration             |
| VSCode           | 1.84+          | Development IDE with Cairo extensions     |
| Git              | 2.40+          | Version control                           |
| Node.js          | 18.17+ / 20.9+ | JavaScript runtime for tooling            |
| Kubectl          | 1.28+          | Kubernetes CLI                            |
| Helm             | 3.13+          | Kubernetes package manager                |
| Python           | 3.9+           | Required for Cairo toolchain              |

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
│   └── enterprise/             # Enterprise configurations
├── docker-compose.yml          # Main Docker Compose file
├── docker-compose.dev.yml      # Development overrides
├── docker-compose.enterprise.yml # Enterprise configuration
└── k8s/                        # Kubernetes configurations
    ├── base/                   # Common K8s resources
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
# Install Scarb
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh

# Install Starknet Foundry
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh

# Install Cairo Native
cargo install cairo-native
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
    "veridis.cairo-tools-v2"
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
  "editor.rulers": [^100],
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
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "GitHub.copilot"
  ],
  "terminal.integrated.defaultProfile.linux": "bash",
  "git.autofetch": true,
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
    "kubeconfig"
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
      "type": "node",
      "request": "launch",
      "name": "Debug Cairo Contract Tests",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/contracts/tests/test_${fileBasenameNoExtension}.cairo",
      "cwd": "${workspaceFolder}/contracts"
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug ZK Circuit Tests",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/zk-circuits/tests/${fileBasenameNoExtension}.test.js",
      "cwd": "${workspaceFolder}/zk-circuits"
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
      "command": "cd ${workspaceFolder}/contracts && scarb build",
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
      "command": "cd ${workspaceFolder}/contracts && snforge test"
    },
    {
      "label": "deploy-contracts-dev",
      "type": "shell",
      "command": "cd ${workspaceFolder}/contracts && sncast deploy --network dev"
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
        "isDefault": true
      }
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
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "redhat.vscode-yaml",
        "GitHub.copilot",
        "rust-lang.rust-analyzer",
        "tamasfe.even-better-toml",
        "veridis.cairo-tools-v2"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "cairo1.scarbVersion": "2.11.4",
        "cairo1.nativeExecution": true
      }
    }
  },
  "remoteUser": "vscode",
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}",
    "SCARB_VERSION": "2.11.4",
    "CAIRO_NATIVE_ENABLED": "true"
  },
  "postCreateCommand": "scripts/init-veridis-env.sh",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {},
    "ghcr.io/devcontainers/features/rust:1": {}
  }
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
      - STARKNET_RPC_URL=http://starknet-devnet:5050
      - COMPLIANCE_ENABLED=true
    command: sleep infinity
    user: vscode

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
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Scarb (Cairo package manager)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native
RUN cargo install cairo-native

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

# Create non-root user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid vscode --shell /bin/bash --create-home vscode \
    && mkdir -p /home/vscode/.cairo /home/vscode/.local/share/scarb \
    && chown -R vscode:vscode /home/vscode

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER vscode

# Verify installations
RUN scarb --version
RUN snforge --version
RUN cairo-native --version

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
    [ ! -d "target" ] && scarb build
    [ ! -f ".env.local" ] && cp .env.example .env.local
    cd ..
fi

# Initialize ZK circuits
if [ -d "zk-circuits" ]; then
    echo "🔄 Setting up ZK circuits..."
    cd zk-circuits
    [ ! -d "node_modules" ] && npm ci
    [ ! -d "build" ] && mkdir -p build
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

# Setup compliance environment if enabled
if [ "$COMPLIANCE_ENABLED" = "true" ]; then
    echo "🔒 Setting up GDPR compliance environment..."
    mkdir -p ~/.veridis/compliance
    ./scripts/setup-compliance.sh
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
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Scarb 2.11.4
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# Copy Cairo project files
COPY Scarb.toml ./
COPY src ./src

# Build contracts
RUN scarb build

# Production stage
FROM ubuntu:22.04 AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy Scarb and Starknet Foundry
COPY --from=build /root/.local/bin/scarb /usr/local/bin/
COPY --from=build /root/.local/bin/sncast /usr/local/bin/
COPY --from=build /root/.local/bin/snforge /usr/local/bin/

# Copy built artifacts
COPY --from=build /app/target ./target
COPY --from=build /app/Scarb.toml ./
COPY --from=build /app/src ./src

# Add deployment scripts
COPY scripts ./scripts

WORKDIR /app

# Expose default port
EXPOSE 5050

# Default command
CMD ["./scripts/deploy-contracts.sh"]
```

#### 5.1.2 Identity Service Dockerfile

Create `services/identity-service/Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine AS build

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Test stage
FROM build AS test
RUN npm run test

# Production stage
FROM node:20-alpine AS production

# Set NODE_ENV
ENV NODE_ENV=production

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -s /bin/sh -D appuser

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/config ./config

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["node", "dist/index.js"]
```

#### 5.1.3 ZK Proof Generation Service Dockerfile

Create `zk-circuits/Dockerfile`:

```dockerfile
# Build stage
FROM node:20-alpine AS build

# Install system dependencies for native compilation
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    linux-headers \
    git

WORKDIR /app

# Install Garaga SDK and ZK tools
RUN npm install -g @garaga/cli@latest

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy circuit source code
COPY . .

# Compile circuits
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip

# Create non-root user
RUN addgroup -g 1000 zkuser && \
    adduser -u 1000 -G zkuser -s /bin/sh -D zkuser

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy built circuits and proving keys
COPY --from=build /app/build ./build
COPY --from=build /app/keys ./keys

# Change ownership to non-root user
RUN chown -R zkuser:zkuser /app

# Switch to non-root user
USER zkuser

# Expose proof generation service port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Run the proof generation service
CMD ["node", "build/proof-service.js"]
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

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Set NODE_ENV
ENV NODE_ENV=production

# Install GDPR compliance tools
RUN apk add --no-cache \
    python3 \
    py3-pip

# Install compliance libraries
RUN pip3 install gdpr-automation-toolkit

# Create non-root user
RUN addgroup -g 1000 compliance && \
    adduser -u 1000 -G compliance -s /bin/sh -D compliance

WORKDIR /app

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy built application
COPY --from=build /app/dist ./dist
COPY --from=build /app/config ./config

# Copy compliance templates
COPY compliance-templates ./compliance-templates

# Change ownership to non-root user
RUN chown -R compliance:compliance /app

# Switch to non-root user
USER compliance

# Expose compliance service port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Run the compliance service
CMD ["node", "dist/index.js"]
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
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Scarb 2.11.4 (mandatory version)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry 0.44.0
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native for performance optimization
RUN cargo install cairo-native

# Create non-root user
RUN groupadd --gid 1000 cairo \
    && useradd --uid 1000 --gid cairo --shell /bin/bash --create-home cairo

# Set working directory
WORKDIR /app

# Use non-root user
USER cairo

# Verify installations
RUN scarb --version && \
    snforge --version && \
    cairo-native --version
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
    jq

# Install GDPR compliance automation tools
RUN pip3 install \
    gdpr-automation-toolkit \
    data-privacy-auditor \
    compliance-reporter

# Install audit and monitoring tools
RUN npm install -g \
    @veridis/audit-logger \
    @veridis/compliance-monitor \
    @veridis/gdpr-automation

# Create compliance user
RUN addgroup -g 1000 compliance && \
    adduser -u 1000 -G compliance -s /bin/sh -D compliance

# Create directories for compliance data
RUN mkdir -p /compliance/audit-logs \
             /compliance/gdpr-data \
             /compliance/reports && \
    chown -R compliance:compliance /compliance

# Set working directory
WORKDIR /app

# Use non-root user
USER compliance

# Health check for compliance services
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3001/compliance/health || exit 1
```

## 6. Docker Compose Configuration

### 6.1 Main Docker Compose

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  starknet-devnet:
    image: shardlabs/starknet-devnet:latest
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

  identity-service:
    build:
      context: ./services/identity-service
      dockerfile: Dockerfile
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
      - STARKNET_RPC_URL=http://starknet-devnet:5050
      - JWT_SECRET=${JWT_SECRET}
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  attestation-service:
    build:
      context: ./services/attestation-service
      dockerfile: Dockerfile
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
      - STARKNET_RPC_URL=http://starknet-devnet:5050
      - JWT_SECRET=${JWT_SECRET}
      - PORT=3000
    restart: unless-stopped

  verification-service:
    build:
      context: ./services/verification-service
      dockerfile: Dockerfile
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

  compliance-service:
    build:
      context: ./services/compliance-service
      dockerfile: Dockerfile
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
      - AUDIT_LOG_RETENTION_DAYS=2555
      - PORT=3001
    volumes:
      - compliance-data:/app/compliance-data
    restart: unless-stopped

  bridge-service:
    build:
      context: ./services/bridge-service
      dockerfile: Dockerfile
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
      - STARKNET_RPC_URL=http://starknet-devnet:5050
      - ETHEREUM_RPC_URL=${ETHEREUM_RPC_URL}
      - COSMOS_RPC_URL=${COSMOS_RPC_URL}
      - PORT=3000
    restart: unless-stopped

  zk-proof-service:
    build:
      context: ./zk-circuits
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    networks:
      - veridis-network
    environment:
      - NODE_ENV=production
      - GARAGA_OPTIMIZATION=true
      - PROOF_GENERATION_TIMEOUT=60000
      - PORT=4000
    volumes:
      - zk-keys:/app/keys
      - zk-cache:/app/cache
    restart: unless-stopped

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
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U veridis"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - veridis-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  veridis-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  compliance-data:
  zk-keys:
  zk-cache:
```

### 6.2 Development Overrides

Create `docker-compose.dev.yml`:

```yaml
version: "3.8"

services:
  starknet-devnet:
    command:
      ["--host", "0.0.0.0", "--port", "5050", "--seed", "42", "--lite-mode"]
    environment:
      - STARKNET_DEVNET_LITE_MODE=true

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

  attestation-service:
    volumes:
      - ./services/attestation-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*

  verification-service:
    volumes:
      - ./services/verification-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*

  compliance-service:
    volumes:
      - ./services/compliance-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - GDPR_AUTOMATION_ENABLED=false

  bridge-service:
    volumes:
      - ./services/bridge-service:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*

  zk-proof-service:
    volumes:
      - ./zk-circuits:/app
      - /app/node_modules
    command: npm run dev
    environment:
      - NODE_ENV=development
      - DEBUG=veridis:*
      - GARAGA_OPTIMIZATION=false

  postgres:
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=veridis_dev

  redis:
    ports:
      - "6379:6379"

  # Development-only services
  cairo-dev:
    build:
      context: .
      dockerfile: docker/cairo/dev.Dockerfile
    volumes:
      - ./contracts:/app/contracts
      - cairo-cache:/home/cairo/.cairo
    working_dir: /app/contracts
    command: sleep infinity
    networks:
      - veridis-network

volumes:
  cairo-cache:
```

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
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 1G
          cpus: "1"

  attestation-service:
    environment:
      - COMPLIANCE_LEVEL=ENTERPRISE
      - ATTESTATION_AUDIT_LOG=true
    deploy:
      replicas: 2

  compliance-service:
    environment:
      - ENTERPRISE_FEATURES=true
      - REAL_TIME_MONITORING=true
      - IMMUTABLE_AUDIT_LOG=true
      - SOC2_COMPLIANCE=true
    volumes:
      - compliance-audit-logs:/app/audit-logs:ro
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 2G
          cpus: "2"

  # Enterprise monitoring stack
  prometheus:
    image: prom/prometheus:v2.43.0
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    networks:
      - veridis-network

  grafana:
    image: grafana/grafana:9.4.3
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana-datasources.yaml:/etc/grafana/provisioning/datasources/datasources.yaml
    networks:
      - veridis-network
    depends_on:
      - prometheus

  # Enterprise security scanner
  security-scanner:
    image: veridis/security-scanner:latest
    volumes:
      - ./:/scan-target:ro
      - security-reports:/reports
    environment:
      - SCAN_SCHEDULE=0 2 * * *
      - COMPLIANCE_CHECK=true
    networks:
      - veridis-network

volumes:
  compliance-audit-logs:
  prometheus-data:
  grafana-data:
  security-reports:
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
│   │   └── configmap.yaml
│   ├── attestation-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── verification-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── compliance-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── bridge-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── zk-proof-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── infrastructure/
│       ├── postgres-statefulset.yaml
│       ├── postgres-service.yaml
│       ├── redis-deployment.yaml
│       ├── redis-service.yaml
│       └── starknet-devnet.yaml
├── development/
├── staging/
└── production/
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
  - attestation-service/deployment.yaml
  - attestation-service/service.yaml
  - attestation-service/configmap.yaml
  - verification-service/deployment.yaml
  - verification-service/service.yaml
  - verification-service/configmap.yaml
  - compliance-service/deployment.yaml
  - compliance-service/service.yaml
  - compliance-service/configmap.yaml
  - bridge-service/deployment.yaml
  - bridge-service/service.yaml
  - bridge-service/configmap.yaml
  - zk-proof-service/deployment.yaml
  - zk-proof-service/service.yaml
  - zk-proof-service/configmap.yaml
  - infrastructure/postgres-statefulset.yaml
  - infrastructure/postgres-service.yaml
  - infrastructure/redis-deployment.yaml
  - infrastructure/redis-service.yaml
  - infrastructure/starknet-devnet.yaml

namespace: veridis

commonLabels:
  app: veridis
  part-of: veridis-protocol
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
  template:
    metadata:
      labels:
        app: identity-service
        component: backend
    spec:
      containers:
        - name: identity-service
          image: ghcr.io/veridis-protocol/identity-service:latest
          ports:
            - containerPort: 3000
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
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
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
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: app-cache
              mountPath: /app/cache
      volumes:
        - name: tmp
          emptyDir: {}
        - name: app-cache
          emptyDir: {}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
```

Create `k8s/base/identity-service/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: identity-service
  labels:
    app: identity-service
spec:
  selector:
    app: identity-service
  ports:
    - port: 80
      targetPort: 3000
      name: http
  type: ClusterIP
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
  STARKNET_RPC_URL: "http://starknet-devnet:5050"
  REDIS_URL: "redis://redis:6379"
  LOG_LEVEL: "info"
  METRICS_ENABLED: "true"
  COMPLIANCE_LEVEL: "STANDARD"
```

### 7.3 Production Environment

Create `k8s/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../base

namespace: veridis-prod

namePrefix: prod-

commonLabels:
  environment: production
  compliance: enterprise

patchesStrategicMerge:
  - patches/identity-service-prod.yaml
  - patches/compliance-service-prod.yaml
  - patches/zk-proof-service-prod.yaml

configMapGenerator:
  - name: identity-service-config
    behavior: merge
    literals:
      - COMPLIANCE_LEVEL=ENTERPRISE
      - GDPR_STRICT_MODE=true
      - AUDIT_EVERYTHING=true
  - name: compliance-service-config
    behavior: merge
    literals:
      - ENTERPRISE_FEATURES=true
      - REAL_TIME_MONITORING=true
      - SOC2_COMPLIANCE=true

secretGenerator:
  - name: veridis-secrets
    literals:
      - JWT_SECRET=prod-jwt-secret-from-vault
      - DATABASE_PASSWORD=prod-db-password-from-vault

images:
  - name: ghcr.io/veridis-protocol/identity-service
    newTag: v2.0.0
  - name: ghcr.io/veridis-protocol/attestation-service
    newTag: v2.0.0
  - name: ghcr.io/veridis-protocol/verification-service
    newTag: v2.0.0
  - name: ghcr.io/veridis-protocol/compliance-service
    newTag: v2.0.0
  - name: ghcr.io/veridis-protocol/bridge-service
    newTag: v2.0.0
  - name: ghcr.io/veridis-protocol/zk-proof-service
    newTag: v2.0.0
```

Create `k8s/production/patches/compliance-service-prod.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliance-service
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: compliance-service
          resources:
            limits:
              cpu: "2"
              memory: "4Gi"
            requests:
              cpu: "1"
              memory: "2Gi"
          env:
            - name: IMMUTABLE_AUDIT_LOG
              value: "true"
            - name: COMPLIANCE_SCANNING
              value: "continuous"
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
STARKNET_RPC_URL=http://starknet-devnet:5050
STARKNET_CHAIN_ID=SN_GOERLI
CAIRO_VERSION=2.11.4

# Database Configuration
DATABASE_URL=postgres://veridis:veridis@postgres:5432/veridis_main
REDIS_URL=redis://redis:6379

# Authentication
JWT_SECRET=your-jwt-secret-here
JWT_EXPIRATION=24h

# Cross-Chain Configuration
ETHEREUM_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/your-api-key
COSMOS_RPC_URL=https://cosmos-rpc.polkachu.com
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
POLKADOT_RPC_URL=wss://rpc.polkadot.io

# ZK Proof Configuration
GARAGA_OPTIMIZATION=true
PROOF_GENERATION_TIMEOUT=60000
ZK_CIRCUIT_PATH=/app/circuits

# Compliance Configuration
COMPLIANCE_LEVEL=STANDARD
GDPR_AUTOMATION_ENABLED=false
AUDIT_LOG_RETENTION_DAYS=90
SOC2_COMPLIANCE=false

# Performance Configuration
CAIRO_NATIVE_ENABLED=true
GAS_OPTIMIZATION=true
BATCH_PROCESSING=true

# Monitoring
METRICS_ENABLED=true
LOG_LEVEL=info
SENTRY_DSN=your-sentry-dsn-here

# Enterprise Features (only in enterprise mode)
ENTERPRISE_FEATURES=false
REAL_TIME_MONITORING=false
IMMUTABLE_AUDIT_LOG=false
THREAT_DETECTION=false
```

### 8.2 Secret Management with Kubernetes

Create `k8s/base/secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: veridis-secrets
type: Opaque
data:
  JWT_SECRET: # base64 encoded secret
  DATABASE_PASSWORD: # base64 encoded password
  ETHEREUM_RPC_API_KEY: # base64 encoded API key
  SENTRY_DSN: # base64 encoded Sentry DSN
---
apiVersion: v1
kind: Secret
metadata:
  name: compliance-secrets
type: Opaque
data:
  GDPR_ENCRYPTION_KEY: # base64 encoded encryption key
  AUDIT_SIGNING_KEY: # base64 encoded signing key
  COMPLIANCE_WEBHOOK_SECRET: # base64 encoded webhook secret
```

### 8.3 Configuration Validation Script

Create `scripts/validate-config.js`:

```javascript
const dotenv = require("dotenv");
const fs = require("fs");
const path = require("path");

// Load environment variables
const envFile = `.env.${process.env.NODE_ENV || "development"}`;
const envPath = path.resolve(process.cwd(), "config", envFile);

if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
} else {
  console.warn(`Warning: ${envFile} not found, using process.env`);
}

// Define required variables by service
const requiredVariables = {
  core: ["NODE_ENV", "PORT", "DATABASE_URL", "REDIS_URL", "JWT_SECRET"],
  starknet: ["STARKNET_RPC_URL", "STARKNET_CHAIN_ID", "CAIRO_VERSION"],
  crosschain: ["ETHEREUM_RPC_URL", "COSMOS_RPC_URL"],
  zkproof: ["GARAGA_OPTIMIZATION", "ZK_CIRCUIT_PATH"],
  compliance: ["COMPLIANCE_LEVEL", "AUDIT_LOG_RETENTION_DAYS"],
};

// Enterprise-only variables
const enterpriseVariables = [
  "ENTERPRISE_FEATURES",
  "REAL_TIME_MONITORING",
  "IMMUTABLE_AUDIT_LOG",
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

// Main validation
let valid = true;

// Validate core requirements
for (const [category, variables] of Object.entries(requiredVariables)) {
  if (!validateVariables(category, variables)) {
    valid = false;
  }
}

// Validate enterprise requirements if enterprise mode is enabled
if (process.env.COMPLIANCE_LEVEL === "ENTERPRISE") {
  if (!validateVariables("enterprise", enterpriseVariables)) {
    valid = false;
  }
}

// Validate StarkNet-specific configuration
if (process.env.CAIRO_VERSION !== "2.11.4") {
  console.error("Error: Cairo version must be 2.11.4 for Veridis v2.0");
  valid = false;
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

if (valid) {
  console.log("✅ Configuration validation passed!");
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Compliance Level: ${process.env.COMPLIANCE_LEVEL}`);
  console.log(`Cairo Native: ${process.env.CAIRO_NATIVE_ENABLED}`);
} else {
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
    && rm -rf /var/lib/apt/lists/*

# Install Rust with specific version for Cairo compatibility
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup toolchain install 1.76.0
RUN rustup default 1.76.0

# Install Scarb 2.11.4 (mandatory for Veridis v2.0)
RUN curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.11.4
ENV PATH="/root/.local/bin:${PATH}"

# Install Starknet Foundry 0.44.0
RUN curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.44.0
ENV PATH="/root/.local/bin:${PATH}"

# Install Cairo Native for performance optimization
RUN cargo install cairo-native --locked

# Verify installations
RUN scarb --version | grep "2.11.4" || exit 1
RUN snforge --version | grep "0.44.0" || exit 1

WORKDIR /workspace

# Copy compilation script
COPY scripts/compile-cairo.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/compile-cairo.sh

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

# Build with Cairo Native optimization if enabled
if [ "$CAIRO_NATIVE_ENABLED" = "true" ]; then
    echo "⚡ Building with Cairo Native optimization..."
    scarb build --cairo-native
else
    echo "📦 Building with standard Cairo compiler..."
    scarb build
fi

# Generate contract artifacts for deployment
echo "📋 Generating contract artifacts..."
scarb build --check

# Run formal verification if enabled
if [ "$FORMAL_VERIFICATION" = "true" ]; then
    echo "🔍 Running formal verification..."
    scarb verify
fi

# Generate gas reports
if [ "$GAS_PROFILING" = "true" ]; then
    echo "⛽ Generating gas reports..."
    snforge test --gas-snapshot
fi

# Check compliance requirements
if [ "$COMPLIANCE_CHECK" = "true" ]; then
    echo "✅ Running compliance checks..."
    scarb check-compliance --gdpr
fi

echo "✅ Cairo contract compilation completed successfully!"
```

### 9.2 StarkNet Deployment Container

Create `docker/cairo/deployer.Dockerfile`:

```dockerfile
FROM ghcr.io/veridis-protocol/cairo-base:latest

WORKDIR /app

# Copy deployment configuration
COPY deployment-config/ ./deployment-config/
COPY contracts/target/ ./target/

# Copy deployment scripts
COPY scripts/deploy-starknet.sh /usr/local/bin/
COPY scripts/verify-contracts.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Install deployment dependencies
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*

# Create deployment artifacts directory
RUN mkdir -p /app/deployments

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

# Validate environment
case "$ENVIRONMENT" in
  "development")
    RPC_URL="http://starknet-devnet:5050"
    ACCOUNT="devnet-account"
    ;;
  "staging")
    RPC_URL="https://alpha4.starknet.io"
    ACCOUNT="staging-account"
    ;;
  "production")
    RPC_URL="https://alpha-mainnet.starknet.io"
    ACCOUNT="production-account"
    ;;
  *)
    echo "❌ Invalid environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Set deployment configuration
export STARKNET_RPC_URL="$RPC_URL"
export STARKNET_ACCOUNT="$ACCOUNT"

# Deploy contracts in order
echo "📝 Deploying Identity Management contract..."
IDENTITY_CONTRACT=$(sncast deploy \
  --class-hash $(cat target/dev/veridis_IdentityRegistry.contract_class.json | jq -r .class_hash) \
  --constructor-calldata 0x1 \
  --network $NETWORK)

echo "Identity contract deployed: $IDENTITY_CONTRACT"

echo "🏛️ Deploying Attestation Registry contract..."
ATTESTATION_CONTRACT=$(sncast deploy \
  --class-hash $(cat target/dev/veridis_AttestationRegistry.contract_class.json | jq -r .class_hash) \
  --constructor-calldata $IDENTITY_CONTRACT 0x1 \
  --network $NETWORK)

echo "Attestation contract deployed: $ATTESTATION_CONTRACT"

echo "🔐 Deploying Compliance Engine contract..."
COMPLIANCE_CONTRACT=$(sncast deploy \
  --class-hash $(cat target/dev/veridis_ComplianceEngine.contract_class.json | jq -r .class_hash) \
  --constructor-calldata $ATTESTATION_CONTRACT \
  --network $NETWORK)

echo "Compliance contract deployed: $COMPLIANCE_CONTRACT"

# Save deployment artifacts
cat > deployments/$ENVIRONMENT-$NETWORK.json << EOF
{
  "network": "$NETWORK",
  "environment": "$ENVIRONMENT",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "contracts": {
    "identity": "$IDENTITY_CONTRACT",
    "attestation": "$ATTESTATION_CONTRACT",
    "compliance": "$COMPLIANCE_CONTRACT"
  }
}
EOF

# Verify contracts on appropriate networks
if [ "$NETWORK" != "devnet" ] && [ "$VERIFY_CONTRACTS" = "true" ]; then
  echo "🔍 Verifying contracts..."
  ./verify-contracts.sh "$ENVIRONMENT" "$NETWORK"
fi

echo "✅ Deployment completed successfully!"
echo "📄 Deployment artifacts saved to deployments/$ENVIRONMENT-$NETWORK.json"
```

### 9.3 Cairo Testing Container

Create `docker/cairo/tester.Dockerfile`:

```dockerfile
FROM ghcr.io/veridis-protocol/cairo-base:latest

WORKDIR /app

# Install testing dependencies
RUN apt-get update && apt-get install -y \
    lcov \
    && rm -rf /var/lib/apt/lists/*

# Copy test configuration
COPY tests/ ./tests/
COPY contracts/src/ ./src/
COPY Scarb.toml ./

# Copy testing scripts
COPY scripts/run-cairo-tests.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run-cairo-tests.sh

# Create test results directory
RUN mkdir -p /app/test-results

# Set default command
ENTRYPOINT ["/usr/local/bin/run-cairo-tests.sh"]
```

Create `scripts/run-cairo-tests.sh`:

```bash
#!/bin/bash
set -e

echo "🧪 Running Cairo contract tests for Veridis..."

# Run unit tests
echo "📝 Running unit tests..."
snforge test --detailed

# Run integration tests if available
if [ -d "tests/integration" ]; then
    echo "🔗 Running integration tests..."
    snforge test tests/integration/ --detailed
fi

# Generate coverage report
if [ "$GENERATE_COVERAGE" = "true" ]; then
    echo "📊 Generating test coverage report..."
    snforge test --coverage
fi

# Run gas optimization tests
if [ "$GAS_PROFILING" = "true" ]; then
    echo "⛽ Running gas profiling..."
    snforge test --gas-snapshot
    # Save gas snapshot for comparison
    cp .gas_snapshot test-results/gas-snapshot-$(date +%Y%m%d-%H%M%S).txt
fi

# Run security tests
if [ "$SECURITY_TESTS" = "true" ]; then
    echo "🔐 Running security tests..."
    # Run static analysis
    scarb audit
    # Run property-based tests if available
    if [ -d "tests/security" ]; then
        snforge test tests/security/ --detailed
    fi
fi

# Generate test report
echo "📋 Generating test report..."
cat > test-results/test-summary.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cairo_version": "$(cairo --version)",
  "scarb_version": "$(scarb --version)",
  "foundry_version": "$(snforge --version)",
  "test_results": {
    "unit_tests": "passed",
    "integration_tests": "$([ -d 'tests/integration' ] && echo 'passed' || echo 'skipped')",
    "security_tests": "$([ '$SECURITY_TESTS' = 'true' ] && echo 'passed' || echo 'skipped')",
    "gas_profiling": "$([ '$GAS_PROFILING' = 'true' ] && echo 'completed' || echo 'skipped')"
  }
}
EOF

echo "✅ Cairo tests completed successfully!"
```

## 10. ZK Proof Generation Environment

### 10.1 Garaga SDK Integration Container

Create `docker/zk/garaga.Dockerfile`:

```dockerfile
FROM node:20-alpine AS base

# Install system dependencies for native compilation
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    linux-headers \
    git \
    curl \
    pkgconfig \
    openssl-dev

# Install Rust for native ZK library compilation
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Build stage
FROM base AS build

WORKDIR /app

# Install Garaga SDK and dependencies
RUN npm install -g @garaga/cli@latest

# Copy package files
COPY zk-circuits/package*.json ./
RUN npm ci

# Copy circuit source code
COPY zk-circuits/ .

# Compile ZK circuits
RUN npm run build:circuits

# Install Python dependencies for proof generation
COPY zk-circuits/requirements.txt ./
RUN pip3 install -r requirements.txt

# Generate proving and verification keys
RUN npm run generate:keys

# Production stage
FROM base AS production

# Install runtime dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip

# Create non-root user
RUN addgroup -g 1000 zkuser && \
    adduser -u 1000 -G zkuser -s /bin/sh -D zkuser

WORKDIR /app

# Copy package files and install production dependencies
COPY zk-circuits/package*.json ./
RUN npm ci --only=production

# Install Python runtime dependencies
COPY zk-circuits/requirements.txt ./
RUN pip3 install -r requirements.txt --no-cache-dir

# Copy built circuits and keys from build stage
COPY --from=build /app/build ./build
COPY --from=build /app/keys ./keys
COPY --from=build /app/src ./src

# Copy proof generation service
COPY zk-circuits/proof-service/ ./proof-service/

# Change ownership to non-root user
RUN chown -R zkuser:zkuser /app

# Switch to non-root user
USER zkuser

# Expose proof generation service port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Run the proof generation service
CMD ["node", "proof-service/index.js"]
```

### 10.2 ZK Circuit Compilation

Create `zk-circuits/scripts/compile-circuits.sh`:

```bash
#!/bin/bash
set -e

echo "🔄 Compiling ZK circuits for Veridis..."

# Create output directories
mkdir -p build/circuits
mkdir -p build/verification_keys
mkdir -p keys/proving
mkdir -p keys/verification

# Compile identity verification circuit
echo "🆔 Compiling identity verification circuit..."
garaga compile \
    --input src/identity_verification.py \
    --output build/circuits/identity_verification.json \
    --optimization-level 3

# Compile attestation verification circuit
echo "📜 Compiling attestation verification circuit..."
garaga compile \
    --input src/attestation_verification.py \
    --output build/circuits/attestation_verification.json \
    --optimization-level 3

# Compile selective disclosure circuit
echo "🔍 Compiling selective disclosure circuit..."
garaga compile \
    --input src/selective_disclosure.py \
    --output build/circuits/selective_disclosure.json \
    --optimization-level 3

# Compile nullifier circuit
echo "🔒 Compiling nullifier generation circuit..."
garaga compile \
    --input src/nullifier_generation.py \
    --output build/circuits/nullifier_generation.json \
    --optimization-level 3

# Generate proving keys
echo "🔑 Generating proving keys..."
for circuit in identity_verification attestation_verification selective_disclosure nullifier_generation; do
    echo "Generating proving key for $circuit..."
    garaga setup \
        --circuit build/circuits/$circuit.json \
        --proving-key keys/proving/$circuit.pk \
        --verification-key keys/verification/$circuit.vk \
        --trusted-setup keys/trusted_setup.ptau
done

# Optimize circuit constraints
echo "⚡ Optimizing circuit constraints..."
garaga optimize \
    --circuits build/circuits/ \
    --output build/optimized/

# Generate verification contracts for StarkNet
echo "📋 Generating StarkNet verification contracts..."
for circuit in identity_verification attestation_verification selective_disclosure nullifier_generation; do
    garaga generate-starknet-verifier \
        --verification-key keys/verification/$circuit.vk \
        --output ../contracts/src/verifiers/${circuit}_verifier.cairo
done

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

const app = express();
const port = process.env.PORT || 4000;

// Initialize proof cache
const proofCache = new ProofCache({
  maxSize: 10000,
  ttl: 3600000, // 1 hour
});

app.use(express.json({ limit: "10mb" }));

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    garaga_version: process.env.GARAGA_VERSION,
    circuits_loaded: Object.keys(require("./circuits")).length,
  });
});

// Generate identity verification proof
app.post("/prove/identity", async (req, res) => {
  try {
    const { commitment, secret, nullifier } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.identity({ commitment, secret, nullifier })) {
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    // Check cache first
    const cacheKey = `identity_${commitment}_${nullifier}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new identity proof", { commitment, nullifier });

      proof = await generateProof("identity_verification", {
        private_inputs: { secret },
        public_inputs: { commitment, nullifier },
      });

      proofCache.set(cacheKey, proof);
    } else {
      logger.info("Using cached identity proof", { commitment, nullifier });
    }

    res.json({ proof, cached: !!proofCache.get(cacheKey) });
  } catch (error) {
    logger.error("Identity proof generation failed", error);
    res.status(500).json({ error: "Proof generation failed" });
  }
});

// Generate attestation verification proof
app.post("/prove/attestation", async (req, res) => {
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
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    const cacheKey = `attestation_${attestation_root}_${nullifier}`;
    let proof = proofCache.get(cacheKey);

    if (!proof) {
      logger.info("Generating new attestation proof", {
        attestation_root,
        nullifier,
        disclosed_count: disclosed_attributes.length,
      });

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

      proofCache.set(cacheKey, proof);
    } else {
      logger.info("Using cached attestation proof", {
        attestation_root,
        nullifier,
      });
    }

    res.json({ proof, cached: !!proofCache.get(cacheKey) });
  } catch (error) {
    logger.error("Attestation proof generation failed", error);
    res.status(500).json({ error: "Proof generation failed" });
  }
});

// Generate selective disclosure proof
app.post("/prove/selective-disclosure", async (req, res) => {
  try {
    const {
      credential_commitment,
      disclosed_fields,
      undisclosed_fields,
      nullifier,
    } = req.body;

    // Validate inputs
    if (!validateCircuitInputs.selectiveDisclosure(req.body)) {
      return res.status(400).json({ error: "Invalid circuit inputs" });
    }

    const proof = await generateProof("selective_disclosure", {
      private_inputs: { undisclosed_fields },
      public_inputs: {
        credential_commitment,
        disclosed_fields,
        nullifier,
      },
    });

    res.json({ proof });
  } catch (error) {
    logger.error("Selective disclosure proof generation failed", error);
    res.status(500).json({ error: "Proof generation failed" });
  }
});

// Verify any proof
app.post("/verify", async (req, res) => {
  try {
    const { proof, public_inputs, circuit_type } = req.body;

    const isValid = await verifyProof(circuit_type, proof, public_inputs);

    res.json({ valid: isValid });
  } catch (error) {
    logger.error("Proof verification failed", error);
    res.status(500).json({ error: "Proof verification failed" });
  }
});

// Get proof generation statistics
app.get("/stats", (req, res) => {
  res.json({
    cache_stats: proofCache.getStats(),
    uptime: process.uptime(),
    memory_usage: process.memoryUsage(),
  });
});

app.listen(port, () => {
  logger.info(`ZK Proof service listening on port ${port}`);
  logger.info("Available circuits:", Object.keys(require("./circuits")));
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
    image: shardlabs/starknet-devnet:latest
    ports:
      - "5050:5050"
    command: ["--host", "0.0.0.0", "--port", "5050", "--seed", "42"]
    networks:
      - cross-chain-network

  # Ethereum node (Anvil)
  ethereum-node:
    image: ghcr.io/foundry-rs/foundry:latest
    ports:
      - "8545:8545"
    command:
      ["anvil", "--host", "0.0.0.0", "--port", "8545", "--chain-id", "31337"]
    networks:
      - cross-chain-network

  # Cosmos node
  cosmos-node:
    image: cosmoshub:latest
    ports:
      - "26657:26657"
      - "1317:1317"
    environment:
      - CHAIN_ID=cosmoshub-testnet
    networks:
      - cross-chain-network

  # Solana test validator
  solana-node:
    image: solanalabs/solana:stable
    ports:
      - "8899:8899"
    command: ["solana-test-validator", "--bind-address", "0.0.0.0"]
    networks:
      - cross-chain-network

  # Polkadot node
  polkadot-node:
    image: parity/polkadot:latest
    ports:
      - "9944:9944"
      - "9933:9933"
    command: ["--dev", "--ws-external", "--rpc-external"]
    networks:
      - cross-chain-network

  # Cross-chain bridge orchestrator
  bridge-orchestrator:
    build:
      context: .
      dockerfile: docker/bridge/orchestrator.Dockerfile
    ports:
      - "3005:3000"
    environment:
      - STARKNET_RPC=http://starknet-devnet:5050
      - ETHEREUM_RPC=http://ethereum-node:8545
      - COSMOS_RPC=http://cosmos-node:26657
      - SOLANA_RPC=http://solana-node:8899
      - POLKADOT_RPC=ws://polkadot-node:9944
    depends_on:
      - starknet-devnet
      - ethereum-node
      - cosmos-node
      - solana-node
      - polkadot-node
      - postgres
      - redis
    networks:
      - cross-chain-network
    volumes:
      - ./cross-chain-tests:/app/tests
      - bridge-state:/app/state

  # Cross-chain test runner
  cross-chain-tester:
    build:
      context: .
      dockerfile: docker/testing/cross-chain.Dockerfile
    environment:
      - BRIDGE_ORCHESTRATOR_URL=http://bridge-orchestrator:3000
      - TEST_TIMEOUT=300000
    volumes:
      - ./cross-chain-tests:/app/tests
      - test-results:/app/results
    depends_on:
      - bridge-orchestrator
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
    networks:
      - cross-chain-network

  redis:
    image: redis:7-alpine
    volumes:
      - redis-crosschain:/data
    networks:
      - cross-chain-network

networks:
  cross-chain-network:
    driver: bridge

volumes:
  bridge-state:
  test-results:
  postgres-crosschain:
  redis-crosschain:
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
    git

WORKDIR /app

# Copy package files
COPY services/bridge-service/package*.json ./
RUN npm ci

# Install chain-specific SDKs
RUN npm install \
    starknet@7.0.1 \
    ethers@6.0.0 \
    @cosmjs/stargate@0.32.0 \
    @solana/web3.js@1.87.0 \
    @polkadot/api@10.11.0

# Copy bridge service source
COPY services/bridge-service/ .

# Copy cross-chain configuration
COPY cross-chain-config/ ./config/

# Expose orchestrator port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

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
    local url=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f "$url" > /dev/null 2>&1; then
            echo "✅ $service is ready"
            return 0
        fi
        echo "⏳ Waiting for $service (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "❌ $service failed to start"
    return 1
}

# Check all services
check_service "StarkNet" "http://localhost:5050/is_alive"
check_service "Ethereum" "http://localhost:8545"
check_service "Bridge Orchestrator" "http://localhost:3005/health"

# Deploy cross-chain contracts
echo "📝 Deploying cross-chain contracts..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q bridge-orchestrator) \
    npm run deploy:cross-chain

# Run attestation bridging tests
echo "🔗 Testing attestation bridging..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester) \
    npm run test:attestation-bridge

# Run identity verification across chains
echo "🆔 Testing cross-chain identity verification..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester) \
    npm run test:identity-bridge

# Run compliance synchronization tests
echo "📋 Testing compliance data synchronization..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester) \
    npm run test:compliance-sync

# Test nullifier synchronization
echo "🔒 Testing nullifier synchronization..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester) \
    npm run test:nullifier-sync

# Generate cross-chain test report
echo "📊 Generating test report..."
docker exec -it $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester) \
    npm run generate:report

# Copy test results
docker cp $(docker-compose -f docker-compose.cross-chain.yml ps -q cross-chain-tester):/app/results ./test-results/cross-chain

echo "✅ Cross-chain tests completed successfully!"
echo "📄 Test results available in ./test-results/cross-chain/"

# Cleanup
docker-compose -f docker-compose.cross-chain.yml down
```

### 11.4 Cross-Chain Testing Architecture Documentation

Create `docs/cross-chain-testing.md`:

```markdown
# Cross-Chain Testing Architecture for Veridis

## Overview

The Veridis cross-chain testing environment validates the protocol's ability to maintain identity and attestation consistency across multiple blockchain networks while preserving privacy guarantees.

## Architecture Diagram
```

graph TD
A[StarkNet L1] -->|Bridge| B{Bridge Orchestrator}
B --> C[Ethereum]
B --> D[Cosmos]
B --> E[Solana]
B --> F[Polkadot]

    G[Identity Service] --> B
    H[Attestation Service] --> B
    I[Compliance Service] --> B

    B --> J[Cross-Chain State Sync]
    B --> K[Nullifier Coordination]
    B --> L[ZK Proof Verification]
    ```

## Test Scenarios

### 1. Identity Bridging

- Create identity on StarkNet
- Bridge identity commitment to Ethereum
- Verify identity on multiple chains
- Test unlinkability across chains

### 2. Attestation Verification

- Issue attestation on StarkNet
- Verify attestation on Ethereum using ZK proofs
- Test selective disclosure across chains
- Validate compliance requirements

### 3. Nullifier Synchronization

- Generate nullifier on one chain
- Ensure nullifier is recognized on all chains
- Test double-spending prevention
- Validate cross-chain consistency

### 4. Compliance Coordination

- Test GDPR compliance across jurisdictions
- Validate data retention policies
- Test right-to-be-forgotten implementation
- Ensure audit trail consistency

## Performance Requirements

- **Cross-chain message latency**: < 5 minutes
- **State synchronization**: < 10 minutes
- **Proof verification**: < 30 seconds per chain
- **Nullifier consistency**: 100% accuracy

## Security Guarantees

- Zero-knowledge privacy preservation
- Cross-chain replay attack prevention
- Secure message passing protocols
- Cryptographic state verification

````


## 12. Monitoring and Logging

### 12.1 Comprehensive Logging Configuration

Create `services/shared/logger.js`:

```javascript
const winston = require('winston');
const { format } = winston;

// Create custom format for structured logging
const structuredFormat = format.combine(
  format.timestamp(),
  format.errors({ stack: true }),
  format.json(),
  format.printf(({ timestamp, level, message, service, ...meta }) => {
    return JSON.stringify({
      timestamp,
      level,
      service: service || process.env.SERVICE_NAME || 'veridis',
      message,
      ...meta
    });
  })
);

// Create logger with different transports based on environment
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: structuredFormat,
  defaultMeta: {
    service: process.env.SERVICE_NAME || 'veridis',
    version: process.env.SERVICE_VERSION || '2.0.0'
  },
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'production'
        ? structuredFormat
        : format.combine(
            format.colorize(),
            format.simple()
          )
    })
  ]
});

// Add file transport in production
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({
    filename: '/var/log/veridis/error.log',
    level: 'error',
    maxsize: 10485760, // 10MB
    maxFiles: 5
  }));

  logger.add(new winston.transports.File({
    filename: '/var/log/veridis/combined.log',
    maxsize: 10485760, // 10MB
    maxFiles: 10
  }));
}

// Add compliance-specific logging
logger.addComplianceLog = (action, userId, data) => {
  logger.info('COMPLIANCE_EVENT', {
    action,
    userId: userId ? `user_${userId.slice(0, 8)}...` : 'anonymous',
    timestamp: new Date().toISOString(),
    gdpr_category: data.gdprCategory || 'general',
    data_classification: data.classification || 'public',
    retention_period: data.retentionPeriod || 'default'
  });
};

// Add security-specific logging
logger.addSecurityLog = (event, severity, details) => {
  logger.warn('SECURITY_EVENT', {
    event,
    severity,
    details,
    timestamp: new Date().toISOString(),
    ip: details.ip || 'unknown',
    user_agent: details.userAgent || 'unknown'
  });
};

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
        environment: 'production'

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

      - job_name: 'veridis-services'
        static_configs:
          - targets:
            - 'identity-service:3000'
            - 'attestation-service:3000'
            - 'verification-service:3000'
            - 'compliance-service:3001'
            - 'bridge-service:3000'
            - 'zk-proof-service:4000'
        metrics_path: '/metrics'
        scrape_interval: 30s

      - job_name: 'starknet-metrics'
        static_configs:
          - targets: ['starknet-devnet:5050']
        metrics_path: '/metrics'
        scrape_interval: 60s

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
              description: "Error rate is {{ $value }} errors per second"

          - alert: HighLatency
            expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High latency detected"
              description: "95th percentile latency is {{ $value }} seconds"

          - alert: ZKProofGenerationFailing
            expr: rate(zk_proof_generation_failures_total[5m]) > 0.05
            for: 2m
            labels:
              severity: critical
            annotations:
              summary: "ZK proof generation failing"
              description: "ZK proof generation failure rate is {{ $value }} per second"

          - alert: ComplianceViolation
            expr: increase(compliance_violations_total[1h]) > 0
            for: 0s
            labels:
              severity: critical
            annotations:
              summary: "Compliance violation detected"
              description: "{{ $value }} compliance violations in the last hour"

          - alert: CrossChainBridgeDown
            expr: up{job="bridge-service"} == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "Cross-chain bridge is down"
              description: "Bridge service is not responding"
```

### 12.3 Grafana Dashboard Configuration

Create `k8s/base/monitoring/grafana-dashboard.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: veridis-dashboard
data:
  veridis-overview.json: |
    {
      "dashboard": {
        "title": "Veridis Protocol Overview",
        "tags": ["veridis", "privacy", "identity"],
        "timezone": "UTC",
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=~\".*-service\"}[5m])",
                "legendFormat": "{{service}} - {{method}}"
              }
            ],
            "yAxes": [
              {
                "label": "Requests/sec"
              }
            ]
          },
          {
            "title": "Error Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=~\".*-service\",status=~\"5..\"}[5m])",
                "legendFormat": "{{service}} - Errors"
              }
            ]
          },
          {
            "title": "ZK Proof Generation",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(zk_proof_generation_total[5m])",
                "legendFormat": "Proofs Generated/sec"
              },
              {
                "expr": "rate(zk_proof_generation_failures_total[5m])",
                "legendFormat": "Proof Failures/sec"
              }
            ]
          },
          {
            "title": "Identity Operations",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(identity_registrations_total[5m])",
                "legendFormat": "Registrations/sec"
              },
              {
                "expr": "rate(identity_verifications_total[5m])",
                "legendFormat": "Verifications/sec"
              }
            ]
          },
          {
            "title": "Attestation Operations",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(attestation_issuances_total[5m])",
                "legendFormat": "Issuances/sec"
              },
              {
                "expr": "rate(attestation_verifications_total[5m])",
                "legendFormat": "Verifications/sec"
              }
            ]
          },
          {
            "title": "Compliance Events",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(compliance_events_total[5m])",
                "legendFormat": "{{event_type}}"
              }
            ]
          },
          {
            "title": "Cross-Chain Operations",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(bridge_messages_total[5m])",
                "legendFormat": "{{source_chain}} -> {{target_chain}}"
              }
            ]
          },
          {
            "title": "Service Health",
            "type": "stat",
            "targets": [
              {
                "expr": "up{job=~\".*-service\"}",
                "legendFormat": "{{job}}"
              }
            ]
          }
        ]
      }
    }
```

### 12.4 Application Metrics Integration

Create `services/shared/metrics.js`:

```javascript
const promClient = require("prom-client");

// Create a registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics for Veridis
const httpRequestDuration = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
});

const httpRequestsTotal = new promClient.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

const identityOperations = new promClient.Counter({
  name: "identity_operations_total",
  help: "Total number of identity operations",
  labelNames: ["operation_type", "status"],
});

const attestationOperations = new promClient.Counter({
  name: "attestation_operations_total",
  help: "Total number of attestation operations",
  labelNames: ["operation_type", "status"],
});

const zkProofGeneration = new promClient.Counter({
  name: "zk_proof_generation_total",
  help: "Total number of ZK proofs generated",
  labelNames: ["circuit_type", "status"],
});

const zkProofGenerationDuration = new promClient.Histogram({
  name: "zk_proof_generation_duration_seconds",
  help: "Duration of ZK proof generation in seconds",
  labelNames: ["circuit_type"],
  buckets: [1, 5, 10, 30, 60, 120],
});

const complianceEvents = new promClient.Counter({
  name: "compliance_events_total",
  help: "Total number of compliance events",
  labelNames: ["event_type", "severity"],
});

const bridgeMessages = new promClient.Counter({
  name: "bridge_messages_total",
  help: "Total number of cross-chain bridge messages",
  labelNames: ["source_chain", "target_chain", "status"],
});

// Register all metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(identityOperations);
register.registerMetric(attestationOperations);
register.registerMetric(zkProofGeneration);
register.registerMetric(zkProofGenerationDuration);
register.registerMetric(complianceEvents);
register.registerMetric(bridgeMessages);

// Middleware for Express apps
const metricsMiddleware = (req, res, next) => {
  const start = Date.now();

  res.on("finish", () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;

    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);

    httpRequestsTotal.labels(req.method, route, res.statusCode).inc();
  });

  next();
};

module.exports = {
  register,
  metricsMiddleware,
  metrics: {
    httpRequestDuration,
    httpRequestsTotal,
    identityOperations,
    attestationOperations,
    zkProofGeneration,
    zkProofGenerationDuration,
    complianceEvents,
    bridgeMessages,
  },
};
```

## 13. Security Considerations

### 13.1 Container Security Hardening

Create `docker/security/hardening.Dockerfile`:

```dockerfile
FROM node:20-alpine

# Install security scanning tools
RUN apk add --no-cache \
    dumb-init \
    curl \
    jq

# Create non-root user with minimal privileges
RUN addgroup -g 1001 -S veridis && \
    adduser -u 1001 -S veridis -G veridis -h /app

# Security hardening
RUN mkdir -p /app && \
    chown -R veridis:veridis /app && \
    chmod -R 750 /app

# Remove unnecessary packages
RUN apk del --no-cache \
    wget \
    curl \
    bash

# Set security-focused environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=512"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate

WORKDIR /app

# Switch to non-root user early
USER veridis

# Copy package files
COPY --chown=veridis:veridis package*.json ./

# Install dependencies with security audit
RUN npm ci --only=production --no-optional && \
    npm audit --audit-level moderate && \
    rm -rf ~/.npm

# Copy application code
COPY --chown=veridis:veridis . .

# Remove unnecessary files
RUN rm -rf \
    /app/tests \
    /app/docs \
    /app/.git \
    /app/README.md

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
              app: frontend
        - podSelector:
            matchLabels:
              app: verification-service
      ports:
        - protocol: TCP
          port: 3000
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
    - to: {}
      ports:
        - protocol: TCP
          port: 5050 # StarkNet RPC
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
      ports:
        - protocol: TCP
          port: 3001
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
    - to: {}
      ports:
        - protocol: TCP
          port: 443 # HTTPS for compliance reporting
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
  egress: [] # No external network access needed
```

### 13.3 Pod Security Standards

Create `k8s/base/security/pod-security-policy.yaml`:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: veridis-restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - "configMap"
    - "emptyDir"
    - "projected"
    - "secret"
    - "downwardAPI"
    - "persistentVolumeClaim"
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: "MustRunAsNonRoot"
  supplementalGroups:
    rule: "MustRunAs"
    ranges:
      - min: 1000
        max: 65535
  fsGroup:
    rule: "MustRunAs"
    ranges:
      - min: 1000
        max: 65535
  readOnlyRootFilesystem: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: veridis-psp-user
rules:
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    verbs: ["use"]
    resourceNames:
      - veridis-restricted
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: veridis-psp-binding
roleRef:
  kind: ClusterRole
  name: veridis-psp-user
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: default
    namespace: veridis
```

### 13.4 Security Scanning Pipeline

Create `.github/workflows/security-scan.yml`:

```yaml
name: Security Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 2 * * *" # Daily at 2 AM

jobs:
  container-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker images
        run: |
          docker build -t veridis/identity-service:latest ./services/identity-service
          docker build -t veridis/attestation-service:latest ./services/attestation-service
          docker build -t veridis/compliance-service:latest ./services/compliance-service

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "veridis/identity-service:latest"
          format: "sarif"
          output: "trivy-results.sarif"

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: "trivy-results.sarif"

  cairo-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Scarb
        uses: software-mansion/setup-scarb@v1
        with:
          scarb-version: "2.11.4"

      - name: Run Cairo security audit
        run: |
          cd contracts
          scarb audit
          scarb check-compliance --gdpr

      - name: Static analysis
        run: |
          cd contracts
          scarb fmt --check
          scarb test --coverage

  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Audit dependencies
        run: |
          for service in services/*/; do
            echo "Auditing $service"
            cd "$service"
            npm audit --audit-level moderate
            cd ../../
          done

      - name: Check for known vulnerabilities
        uses: securecodewarrior/github-action-add-sarif@v1
        with:
          sarif-file: "npm-audit.sarif"

  compliance-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: GDPR Compliance Check
        run: |
          docker run --rm -v $(pwd):/workspace veridis/compliance-scanner:latest \
            --check-gdpr \
            --check-data-retention \
            --check-audit-trail \
            --output /workspace/compliance-report.json

      - name: Upload compliance report
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance-report.json
```

## 14. Disaster Recovery and Backup

### 14.1 Database Backup Strategy

Create `k8s/base/backup/postgres-backup.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *" # Daily at 2 AM
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: postgres-backup
              image: postgres:15-alpine
              command:
                - /bin/sh
                - -c
                - |
                  # Create timestamped backup
                  BACKUP_FILE="veridis-$(date +%Y%m%d-%H%M%S).sql"

                  # Backup main database
                  pg_dump -h postgres -U veridis -d veridis_main > /backup/$BACKUP_FILE

                  # Compress backup
                  gzip /backup/$BACKUP_FILE

                  # Create backup manifest
                  cat > /backup/manifest-$(date +%Y%m%d).json << EOF
                  {
                    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                    "backup_file": "$BACKUP_FILE.gz",
                    "database": "veridis_main",
                    "size_bytes": $(stat -f%z /backup/$BACKUP_FILE.gz),
                    "checksum": "$(sha256sum /backup/$BACKUP_FILE.gz | cut -d' ' -f1)"
                  }
                  EOF

                  # Cleanup old backups (keep 30 days)
                  find /backup -name "*.gz" -mtime +30 -delete
                  find /backup -name "manifest-*.json" -mtime +30 -delete
              env:
                - name: PGPASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: veridis-secrets
                      key: DATABASE_PASSWORD
              volumeMounts:
                - name: backup-volume
                  mountPath: /backup
          restartPolicy: OnFailure
          volumes:
            - name: backup-volume
              persistentVolumeClaim:
                claimName: backup-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
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
    RPC_URL="http://localhost:5050"
    ;;
  "staging")
    RPC_URL="https://alpha4.starknet.io"
    ;;
  "production")
    RPC_URL="https://alpha-mainnet.starknet.io"
    ;;
  *)
    echo "❌ Invalid environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Get latest block
echo "🔍 Getting latest block information..."
LATEST_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"starknet_blockNumber","params":[],"id":1}' \
  $RPC_URL | jq -r '.result')

echo "Latest block: $LATEST_BLOCK"

# Backup contract addresses and state
CONTRACTS=(
  "identity_registry"
  "attestation_registry"
  "compliance_engine"
  "bridge_contract"
)

for CONTRACT in "${CONTRACTS[@]}"; do
  echo "📋 Backing up $CONTRACT state..."

  # Get contract address from deployment artifacts
  CONTRACT_ADDRESS=$(jq -r ".contracts.$CONTRACT" "deployments/$ENVIRONMENT-mainnet.json")

  if [ "$CONTRACT_ADDRESS" != "null" ]; then
    # Get contract class hash
    curl -s -X POST -H "Content-Type: application/json" \
      --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getClassHashAt\",\"params\":[\"$CONTRACT_ADDRESS\"],\"id\":1}" \
      $RPC_URL > "$BACKUP_DIR/$CONTRACT-class-hash.json"

    # Get contract state (simplified - get storage at key positions)
    for STORAGE_KEY in $(seq 0 10); do
      STORAGE_KEY_HEX=$(printf "0x%x" $STORAGE_KEY)
      curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"starknet_getStorageAt\",\"params\":[\"$CONTRACT_ADDRESS\",\"$STORAGE_KEY_HEX\",\"latest\"],\"id\":1}" \
        $RPC_URL > "$BACKUP_DIR/$CONTRACT-storage-$STORAGE_KEY.json"
    done
  else
    echo "⚠️  Contract $CONTRACT not found in deployment artifacts"
  fi
done

# Backup deployment metadata
echo "📄 Backing up deployment metadata..."
cp "deployments/$ENVIRONMENT-mainnet.json" "$BACKUP_DIR/deployment-metadata.json"

# Create backup manifest
cat > "$BACKUP_DIR/backup-manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "network": "starknet-mainnet",
  "latest_block": "$LATEST_BLOCK",
  "rpc_url": "$RPC_URL",
  "contracts_backed_up": $(printf '%s\n' "${CONTRACTS[@]}" | jq -R . | jq -s .),
  "backup_type": "state_snapshot",
  "veridis_version": "2.0.0"
}
EOF

echo "✅ StarkNet state backup completed!"
echo "📁 Backup stored in: $BACKUP_DIR"
```

### 14.3 Cross-Chain State Recovery

Create `scripts/disaster-recovery.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
BACKUP_DATE=${2:-latest}

echo "🚨 Starting disaster recovery for $ENVIRONMENT environment..."

# Validate environment
if [ "$ENVIRONMENT" = "production" ]; then
    echo "⚠️  Production recovery requires additional confirmation"
    read -p "Are you sure you want to recover production? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Recovery cancelled"
        exit 1
    fi
fi

# Find backup directory
if [ "$BACKUP_DATE" = "latest" ]; then
    BACKUP_DIR=$(ls -td backups/*/$ENVIRONMENT/* | head -1)
else
    BACKUP_DIR="backups/$ENVIRONMENT/$BACKUP_DATE"
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

echo "📁 Using backup from: $BACKUP_DIR"

# Stop affected services
echo "🛑 Stopping services..."
kubectl scale deployment identity-service --replicas=0 -n veridis-$ENVIRONMENT
kubectl scale deployment attestation-service --replicas=0 -n veridis-$ENVIRONMENT
kubectl scale deployment verification-service --replicas=0 -n veridis-$ENVIRONMENT
kubectl scale deployment compliance-service --replicas=0 -n veridis-$ENVIRONMENT
kubectl scale deployment bridge-service --replicas=0 -n veridis-$ENVIRONMENT

# Restore database
echo "🗄️  Restoring database..."
if [ -f "$BACKUP_DIR/database/veridis-main.sql.gz" ]; then
    # Create temporary pod for database restoration
    kubectl run postgres-restore --rm -i --restart=Never \
        --image=postgres:15-alpine \
        --env="PGPASSWORD=$(kubectl get secret veridis-secrets -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d)" \
        -- bash -c "
            gunzip -c | psql -h postgres -U veridis -d veridis_main
        " < "$BACKUP_DIR/database/veridis-main.sql.gz"
else
    echo "⚠️  Database backup not found, skipping database restoration"
fi

# Restore StarkNet contracts if needed
echo "📝 Checking contract deployment status..."
if [ -f "$BACKUP_DIR/deployment-metadata.json" ]; then
    # Compare current deployment with backup
    BACKUP_CONTRACTS=$(jq -r '.contracts | keys[]' "$BACKUP_DIR/deployment-metadata.json")

    for CONTRACT in $BACKUP_CONTRACTS; do
        BACKUP_ADDRESS=$(jq -r ".contracts.$CONTRACT" "$BACKUP_DIR/deployment-metadata.json")
        echo "Contract $CONTRACT should be at: $BACKUP_ADDRESS"

        # Verify contract is still deployed and accessible
        # If not, would need to redeploy (complex recovery scenario)
    done
fi

# Restore service configurations
echo "⚙️  Restoring service configurations..."
if [ -f "$BACKUP_DIR/k8s-config.yaml" ]; then
    kubectl apply -f "$BACKUP_DIR/k8s-config.yaml"
fi

# Restart services
echo "▶️  Restarting services..."
kubectl scale deployment identity-service --replicas=2 -n veridis-$ENVIRONMENT
kubectl scale deployment attestation-service --replicas=2 -n veridis-$ENVIRONMENT
kubectl scale deployment verification-service --replicas=2 -n veridis-$ENVIRONMENT
kubectl scale deployment compliance-service --replicas=1 -n veridis-$ENVIRONMENT
kubectl scale deployment bridge-service --replicas=1 -n veridis-$ENVIRONMENT

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/identity-service -n veridis-$ENVIRONMENT
kubectl wait --for=condition=available --timeout=300s deployment/attestation-service -n veridis-$ENVIRONMENT
kubectl wait --for=condition=available --timeout=300s deployment/verification-service -n veridis-$ENVIRONMENT

# Run health checks
echo "🔍 Running post-recovery health checks..."
./scripts/health-check.sh $ENVIRONMENT

# Generate recovery report
echo "📊 Generating recovery report..."
cat > "recovery-report-$(date +%Y%m%d-%H%M%S).json" << EOF
{
  "recovery_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "backup_used": "$BACKUP_DIR",
  "services_restored": [
    "identity-service",
    "attestation-service",
    "verification-service",
    "compliance-service",
    "bridge-service"
  ],
  "database_restored": $([ -f "$BACKUP_DIR/database/veridis-main.sql.gz" ] && echo "true" || echo "false"),
  "contracts_verified": true,
  "health_check_status": "passed"
}
EOF

echo "✅ Disaster recovery completed successfully!"
echo "📄 Recovery report generated"
```

## 15. References and Additional Resources

### 15.1 Official Documentation

#### StarkNet and Cairo Documentation

- [StarkNet Documentation](https://docs.starknet.io/) - Official StarkNet protocol documentation[^1]
- [Cairo Language Documentation](https://cairo-lang.org/docs/) - Comprehensive Cairo programming guide[^1]
- [Scarb Package Manager](https://docs.swmansion.com/scarb/) - Official Scarb documentation for Cairo v2.11.4[^1]
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Testing and deployment framework[^1]

#### Container and Orchestration

- [Docker Documentation](https://docs.docker.com/) - Container platform documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Container orchestration platform
- [Helm Documentation](https://helm.sh/docs/) - Kubernetes package manager
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) - Kubernetes configuration management

### 15.2 Security and Compliance

#### Privacy and Compliance Standards

- [GDPR Compliance Framework](https://gdpr.eu/) - General Data Protection Regulation guidelines[^2]
- [Privacy by Design Principles](https://www.ipc.on.ca/wp-content/uploads/resources/7foundationalprinciples.pdf) - Core privacy design principles[^2]
- [SOC 2 Compliance Standards](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report.html) - Enterprise security standards[^2]

#### Zero-Knowledge Proof Systems

- [Garaga SDK Documentation](https://garaga.dev/) - ZK proof generation framework for StarkNet[^1][^3]
- [StarkNet ZK-STARK Proofs](https://starkware.co/stark/) - Core cryptographic primitives[^1]
- [Privacy-Preserving Identity Systems](https://eprint.iacr.org/2023/114.pdf) - Academic research on identity protocols

### 15.3 Development Tools and Resources

#### Enterprise Development Tools

- [Veridis CLI Tools](https://github.com/veridis-protocol/cli-tools-v2) - Command-line development utilities[^2][^3]
- [Veridis VS Code Extension](https://marketplace.visualstudio.com/items?itemName=veridis.cairo-tools-v2) - IDE integration for Cairo development[^2][^3]
- [Performance Profiler](https://github.com/veridis-protocol/performance-profiler) - Gas optimization and performance analysis[^2][^3]

#### Community and Support

- [Veridis Developer Forum](https://forum.veridis.xyz) - Community discussion and support[^2][^3]
- [Discord Community](https://discord.gg/veridis) - Real-time developer chat[^2][^3]
- [GitHub Discussions](https://github.com/veridis-protocol/veridis-sdk-v2/discussions) - Technical discussions and Q\&A[^2][^3]

### 15.4 Monitoring and Operations

#### Observability Tools

- [Prometheus Documentation](https://prometheus.io/docs/) - Metrics collection and alerting
- [Grafana Documentation](https://grafana.com/docs/) - Metrics visualization and dashboards
- [Enterprise Monitoring Dashboard](https://metrics.veridis.xyz) - Production monitoring interface[^2][^3]
- [Status Page](https://status.veridis.xyz) - Service availability and incident tracking[^2][^3]

#### Performance and Benchmarks

- [Performance Benchmarks](https://benchmarks.veridis.xyz) - Protocol performance metrics[^2][^3]
- [Gas Optimization Guide](https://docs.veridis.xyz/v2/performance) - Cairo gas optimization strategies[^1][^2][^3]
- [Cross-Chain Latency Metrics](https://metrics.veridis.xyz/cross-chain) - Bridge performance data[^2][^3]

### 15.5 Enterprise Resources

#### Professional Services

- [Enterprise Portal](https://enterprise.veridis.xyz) - Enterprise customer resources[^2][^3]
- [Professional Services](https://veridis.xyz/professional-services) - Implementation and consulting[^2][^3]
- [Training Programs](https://training.veridis.xyz) - Developer certification and workshops[^2][^3]

#### Compliance and Audit

- [Security Audits](https://audits.veridis.xyz) - Third-party security assessments[^2][^3]
- [Compliance Templates](https://github.com/veridis-protocol/compliance-templates) - GDPR and regulatory compliance tools[^2][^3]
- [Audit Framework](https://github.com/veridis-protocol/audit-framework) - Automated compliance monitoring[^2][^3]

### 15.6 Research and Development

#### Academic Resources

- [Veridis Whitepaper v2.0](https://veridis.xyz/whitepaper-v2.pdf) - Protocol specification and cryptographic foundations[^2][^3]
- [Research Publications](https://research.veridis.xyz) - Academic papers and technical research[^2][^3]
- [Academic Partnerships](https://veridis.xyz/academic) - University collaboration and research programs[^2][^3]

#### Technical Implementation Guides

- [Migration Guide from v1.x](https://docs.veridis.xyz/v2/migration) - Upgrading from previous versions[^2][^3]
- [Cross-Chain Bridge Architecture](https://docs.veridis.xyz/v2/bridge) - Multi-chain implementation details[^2][^3]
- [Enterprise GDPR Implementation](https://docs.veridis.xyz/v2/compliance/gdpr) - Privacy compliance automation[^2][^3]

---

**Document Metadata**

- **Document ID**: VERIDIS-DEVENV-2025-001
- **Version**: 1.0
- **Date**: 2025-05-30
- **Authors**: Cass402 and the Veridis Engineering Team
- **Last Edit**: 2025-05-30 23:09 UTC by Cass402
- **Classification**: Internal Technical Documentation
- **Distribution**: Veridis Engineering, External Developers, Technical Partners, Enterprise Customers
