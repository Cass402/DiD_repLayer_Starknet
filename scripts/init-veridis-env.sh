#!/bin/bash

# VERIDIS DEVELOPMENT ENVIRONMENT INITIALIZATION SCRIPT
#
# This script initializes the complete Veridis development environment by setting up
# all necessary components, dependencies, and configurations for the zero-knowledge
# identity verification platform.
#
# USAGE:
#   ./scripts/init-veridis-env.sh
#
# PREREQUISITES:
#   - Node.js and npm installed
#   - Python 3.x installed (for Python SDK)
#   - Scarb Cairo toolchain (for contracts)
#   - Run from the root directory of the Veridis repository
#
# ENVIRONMENT VARIABLES:
#   FORMAL_VERIFICATION_ENABLED  - Set to "true" to enable formal verification setup
#   COMPLIANCE_ENABLED          - Set to "true" to enable GDPR compliance setup
#   SECURITY_SCANNING_ENABLED   - Set to "true" to enable security scanning
#
# COMPONENTS INITIALIZED:
#   1. Root Project Dependencies
#      - Validates repository root location
#      - Installs npm dependencies from package-lock.json
#
#   2. Cairo Contracts Environment
#      - Runs scarb-native-dump to build contracts
#      - Creates local environment configuration
#
#   3. ZK Circuits Environment
#      - Installs circuit dependencies
#      - Creates build and cryptographic keys directories
#
#   4. Microservices Setup
#      - identity-service: User identity management
#      - attestation-service: Credential attestation
#      - verification-service: Zero-knowledge proof verification
#      - compliance-service: Regulatory compliance
#      - bridge-service: Cross-chain interoperability
#
#   5. Client SDKs
#      - TypeScript SDK: Web and Node.js integration
#      - Python SDK: Python application integration (with virtual environment)
#      - Mobile SDK: Mobile application development
#
#   6. Optional Components (Environment-dependent)
#      - Formal verification tools
#      - GDPR compliance framework
#      - Security scanning tools
#      - GPU acceleration for ZK proof generation
#
# DIRECTORY STRUCTURE CREATED:
#   ~/.veridis/
#   ├── formal-verification/     (if enabled)
#   └── compliance/              (if enabled)
#
#   ./
#   ├── node_modules/
#   ├── contracts/target/
#   ├── zk-circuits/
#   │   ├── node_modules/
#   │   ├── build/
#   │   └── keys/
#   │       ├── proving/
#   │       └── verification/
#   ├── services/*/node_modules/
#   └── client-sdk/*/
#       ├── node_modules/        (TypeScript/Mobile)
#       └── venv/               (Python only)
#
# EXIT CODES:
#   0 - Success
#   1 - Error (package.json not found, invalid directory)
#
# NOTES:
#   - Script uses 'set -e' for fail-fast behavior
#   - All dependency installations use 'npm ci' for reproducible builds
#   - Environment files are created from .env.example templates
#   - GPU acceleration setup is automatically detected for NVIDIA hardware
#   - Missing optional scripts generate warnings but don't fail the initialization

set -e # Exit on error

echo "🚀 Initializing Veridis development environment..."

# Check if package.json exists in the current directory
# If not found, display an error message and exit with status code 1
# This ensures the script is being run from the correct repository root directory
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found in the current directory. Please run this script from the root of the Veridis repository."
  exit 1
fi

# Checks if node_modules directory exists in the current working directory.
# If the directory does not exist, displays an installation message and runs
# npm ci to install dependencies from package-lock.json in a clean state.
# This ensures reproducible builds by installing exact dependency versions.
if [ ! -d "node_modules" ]; then
  echo "📦 Installing root dependencies..."
  npm ci
fi

# Initializes Cairo contracts environment if contracts directory exists
# - Changes to contracts directory
# - Runs scarb-native-dump if target directory doesn't exist
# - Creates .env.local from .env.example if .env.local doesn't exist and .env.example is present
# - Returns to parent directory
if [ -d "contracts" ]; then
  echo "📝 Setting up Cairo contracts..."
  cd contracts
  [ ! -d "target" ] && scarb-native-dump
  [ ! -f ".env.local" ] && [ -f ".env.example" ] && cp .env.example .env.local
  cd ..
fi

# Check if zk-circuits directory exists and set up the ZK circuits environment
# - Installs npm dependencies if node_modules doesn't exist
# - Creates build directory if it doesn't exist
# - Creates keys directory structure (proving and verification subdirectories) if it doesn't exist
# - Returns to parent directory after setup
if [ -d "zk-circuits" ]; then
  echo "🔄 Setting up ZK circuits..."
  cd zk-circuits
  [ ! -d "node_modules" ] && npm ci
  [ ! -d "build" ] && mkdir -p build
  [ ! -d "keys" ] && mkdir -p keys/proving keys/verification
  cd ..
fi

# Loop through all microservices in the Veridis ecosystem and initialize their development environments
# Services include: identity, attestation, verification, compliance, and bridge services
# For each service directory that exists:
# - Install dependencies using npm ci (clean install from package-lock.json)
# - Create local environment file from example template if it doesn't exist
# This ensures all services have their dependencies installed and environment configured
for service in identity-service attestation-service verification-service compliance-service bridge-service; do
  if [ -d "services/$service" ]; then
    echo "🔧 Setting up $service..."
    cd "services/$service"
    [ ! -d "node_modules" ] && npm ci
    [ ! -f ".env.local" ] && [ -f ".env.example" ] && cp .env.example .env.local
    cd ../..
  fi
done

# Initialize and set up development environments for multiple client SDKs
# This script iterates through typescript, python, and mobile SDK directories
# and performs the following setup tasks:
#
# For Python SDK:
# - Creates a virtual environment (venv) if it doesn't exist
# - Activates the virtual environment
# - Installs dependencies from requirements.txt if present
#
# For TypeScript/Mobile SDKs:
# - Installs dependencies using npm ci if node_modules doesn't exist
#
# The script maintains proper directory navigation by returning to the
# original directory after processing each SDK
for sdk in typescript python mobile; do
  if [ -d "client-sdk/$sdk" ]; then
    echo "📱 Setting up $sdk SDK..."
    cd "client-sdk/$sdk"
    if [ "$sdk" = "python" ]; then
      [ ! -d "venv" ] && python3 -m venv venv
      source venv/bin/activate
      if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
      fi
    else
      [ ! -d "node_modules" ] && npm ci
    fi
    cd ../..
  fi
done

# Conditional setup for formal verification environment
# Checks if formal verification is enabled via environment variable and creates necessary directories
# Executes formal verification setup script if available, otherwise provides warning message
# Creates ~/.veridis/formal-verification directory structure for verification tools
# Depends on: FORMAL_VERIFICATION_ENABLED environment variable and scripts/setup-formal-verification.sh
if [ "$FORMAL_VERIFICATION_ENABLED" = "true" ]; then
  echo "🔍 Setting up formal verification environment..."
  mkdir -p ~/.veridis/formal-verification
  if [ -f "scripts/setup-formal-verification.sh" ]; then
    ./scripts/setup-formal-verification.sh
  else
    echo "Warning: setup-formal-verification.sh script not found. Skipping formal verification setup."
  fi
fi

# Check if GDPR compliance is enabled via environment variable
# If enabled, create compliance directory structure and execute compliance setup script
# Provides graceful fallback with warning message if setup script is not found
# This ensures the application can handle GDPR requirements when compliance is mandatory
if [ "$COMPLIANCE_ENABLED" = "true" ]; then
  echo "🔒 Setting up GDPR compliance environment..."
  mkdir -p ~/.veridis/compliance
  if [ -f "scripts/setup-compliance.sh" ]; then
    ./scripts/setup-compliance.sh
  else
    echo "Warning: setup-compliance.sh script not found. Skipping compliance setup."
  fi
fi

# Security scanning initialization block
# Conditionally executes security scanning based on environment variable
#
# Environment Variables:
#   SECURITY_SCANNING_ENABLED - Set to "true" to enable security scanning
#
# Dependencies:
#   scripts/run-security-scan.sh - Security scanning script (optional)
#
# Behavior:
#   - Checks if security scanning is enabled via environment variable
#   - If enabled, attempts to run the security scan script
#   - Provides fallback warning if the security scan script is not found
#   - Gracefully continues execution even if security script is missing
if [ "$SECURITY_SCANNING_ENABLED" = "true" ]; then
  echo "🛡️ Running initial security scan..."
  if [ -f "scripts/run-security-scan.sh" ]; then
    ./scripts/run-security-scan.sh
  else
    echo "Warning: run-security-scan.sh script not found. Skipping security scan."
  fi
fi

# Check if NVIDIA GPU is available and set up GPU acceleration for Zero-Knowledge proofs
# This section detects NVIDIA GPUs using nvidia-smi command and conditionally runs
# the GPU acceleration setup script if the hardware is available and the script exists
# Provides appropriate warnings if the setup script is missing
if command -v nvidia-smi &> /dev/null; then
  echo "🖥️ Setting up GPU acceleration for ZK proofs..."
  if [ -f "scripts/setup-gpu-acceleration.sh" ]; then
    ./scripts/setup-gpu-acceleration.sh
  else
    echo "Warning: setup-gpu-acceleration.sh script not found. Skipping GPU acceleration setup."
  fi
fi

echo "✅ Veridis development environment initialization complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. Review .env.local files in each service"
echo "  2. Start development: npm run dev"
echo "  3. Run tests: npm test"
echo "  4. View documentation: npm run docs"
echo ""
echo "🔗 Useful commands:"
echo "  • Build contracts: cd contracts && scarb build"
echo "  • Generate ZK proofs: cd zk-circuits && npm run generate"
echo "  • Run security scan: SECURITY_SCANNING_ENABLED=true ./scripts/init-veridis-env.sh"
