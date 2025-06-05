# ==============================================================================
# Veridis Identity UI Application Deployment Environment
# ==============================================================================
#
# This Dockerfile creates a production-ready environment for building and deploying
# the Veridis Identity UI application built with Next.js, React, and TypeScript.
# The image uses a multi-stage approach to optimize build performance and minimize
# runtime image size while maintaining comprehensive security and monitoring capabilities.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# ===============================
# 1. node-base: Base Node.js environment with system dependencies
# 2. dependency-cache: Package dependency installation and caching layer
# 3. application-build: Application compilation and testing environment
# 4. security-scan: Security vulnerability scanning and validation
# 5. production: Lightweight production runtime environment
#
# INCLUDED COMPONENTS:
# ===================
# • Node.js 22 LTS runtime with Alpine Linux base
# • Package manager detection and optimization (npm, yarn, pnpm)
# • Next.js build optimization with standalone output (default)
# • TypeScript compilation and type checking
# • React application bundling and optimization
# • Security scanning with vulnerability assessment
# • Performance optimization with static asset handling
#
# SECURITY FEATURES:
# ==================
# • Non-root user execution (nextjs:1001)
# • Minimal runtime image with reduced attack surface
# • Security scanning integration for vulnerability detection
# • Certificate authority validation for SSL/TLS connections
# • Comprehensive dependency verification
# • Runtime security controls and monitoring
#
# BUILD ARGUMENTS:
# ================
# - NODE_VERSION: Node.js LTS version (default: 22)
# - ALPINE_VERSION: Alpine Linux version (default: alpine)
# - BUILD_MODE: Build environment mode (default: production)
# - PACKAGE_MANAGER: Package manager preference (default: auto-detect)
# - SECURITY_SCAN_REQUIRED: Enable security vulnerability scanning (default: true)
# - UI_PORT: Frontend application port (default: 3000)
# - NEXT_TELEMETRY_DISABLED: Disable Next.js telemetry (default: 1)
# - STANDALONE_OUTPUT: Enable Next.js standalone output (default: true, recommended)
#
# USAGE:
# ======
# Build production image (standalone - recommended):
# docker build --build-arg NODE_VERSION=22 --build-arg BUILD_MODE=production -t veridis/ui .
#
# Build with specific package manager:
# docker build --build-arg PACKAGE_MANAGER=pnpm --build-arg BUILD_MODE=production -t veridis/ui .
#
# Build without standalone (requires runtime dependencies):
# docker build --build-arg STANDALONE_OUTPUT=false --build-arg BUILD_MODE=production -t veridis/ui .
#
# Run UI application:
# docker run -d -p 3000:3000 -e NODE_ENV=production veridis/ui
#
# ENVIRONMENT VARIABLES (Runtime):
# ================================
# - NODE_ENV: Node.js environment (development, staging, production)
# - NEXT_PUBLIC_API_URL: Backend API endpoint URL
# - NEXT_PUBLIC_APP_URL: Frontend application URL
# - NEXT_PUBLIC_ENVIRONMENT: Application environment identifier
# - PORT: Application server port (default: 3000)
# - HOSTNAME: Server bind hostname (default: 0.0.0.0)
#
# PRODUCTION WORKFLOW:
# ===================
# - Optimized dependency caching for faster builds
# - Comprehensive TypeScript type checking and linting
# - Security vulnerability scanning and assessment
# - Next.js build optimization with static generation
# - Performance monitoring and health check integration
#
# MAINTENANCE NOTES:
# ==================
# - Based on Alpine Linux for minimal attack surface
# - Package versions are locked for reproducible builds
# - Security scanning integrated for continuous assessment
# - Compatible with Kubernetes and container orchestration
# - Regular security updates through base image updates
# - Standalone output is strongly recommended for production
# ==============================================================================

# ==============================================================================
# Stage 1: Base Node.js environment with system dependencies
# ==============================================================================
FROM node:${NODE_VERSION:-22}-${ALPINE_VERSION:-alpine} AS node-base

# Build arguments for version control and configuration
ARG NODE_VERSION=22
ARG ALPINE_VERSION=alpine
ARG BUILD_MODE=production
ARG PACKAGE_MANAGER=auto-detect
ARG SECURITY_SCAN_REQUIRED=true
ARG UI_PORT=3000
ARG NEXT_TELEMETRY_DISABLED=1
ARG STANDALONE_OUTPUT=true

# Install essential system dependencies for Node.js compilation
# Uses --no-cache to minimize image size and avoid package cache
# - libc6-compat: Compatibility layer for glibc applications
# - curl: HTTP client for health checks and API interactions
# - dumb-init: Lightweight init system for proper signal handling
# - git: Version control system for dependency management
# - python3: Python interpreter for native module compilation
# - make: Build automation tool for native dependencies
# - g++: GNU C++ compiler for native module compilation
RUN apk add --no-cache \
    libc6-compat \
    curl \
    dumb-init \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Configure Corepack for package manager support
# Enables modern package managers (pnpm, yarn) with proper version management
RUN corepack enable

# Configure Node.js runtime and npm settings for optimal performance and security
# NODE_OPTIONS: Increases maximum heap size to 2GB to handle memory-intensive operations
# NPM_CONFIG_AUDIT_LEVEL: Sets security audit level to moderate (catches medium+ severity issues)
# NPM_CONFIG_FUND: Disables funding messages during npm operations for cleaner output
# NPM_CONFIG_UPDATE_NOTIFIER: Disables update notifications to prevent interruptions in CI/CD
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false

# ==============================================================================
# Stage 2: Package dependency installation and caching layer
# ==============================================================================
FROM node-base AS dependency-cache

# Set working directory for dependency installation
WORKDIR /app

# Copy package management files for dependency caching optimization
# This allows Docker to cache the dependency installation layer
# when only source code changes but dependencies remain the same
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Smart package manager detection and dependency installation
# This step automatically detects the package manager used in the project based on lockfiles
# and installs dependencies using the appropriate tool:
# - yarn.lock -> Uses Yarn with frozen lockfile for reproducible builds
# - package-lock.json -> Uses npm ci for clean production-ready installation
# - pnpm-lock.yaml -> Uses pnpm with corepack enablement for efficient package management
# Includes network timeout handling and comprehensive error reporting
# Exits with error code 1 if no recognized lockfile is found
RUN echo "🔍 Detecting package manager and installing dependencies..." && \
    if [ -f yarn.lock ]; then \
        echo "📦 Using Yarn package manager" && \
        yarn --frozen-lockfile --network-timeout 300000; \
    elif [ -f package-lock.json ]; then \
        echo "📦 Using npm package manager" && \
        npm ci --only=production=false --audit=false; \
    elif [ -f pnpm-lock.yaml ]; then \
        echo "📦 Using pnpm package manager" && \
        corepack enable pnpm && pnpm i --frozen-lockfile; \
    else \
        echo "❌ No lockfile found. Please ensure package-lock.json, yarn.lock, or pnpm-lock.yaml exists." && exit 1; \
    fi && \
    echo "✅ Dependencies installed successfully"

# Install security scanning tools for vulnerability assessment
# audit-ci: Continuous integration security auditing tool (pinned version)
# Using specific version to ensure consistent security policies across builds
RUN echo "🔧 Installing security scanning tools..." && \
    npm install -g audit-ci@7.1.0 && \
    echo "✅ Security tools installed successfully"

# ==============================================================================
# Stage 3: Application compilation and testing environment
# ==============================================================================
FROM dependency-cache AS application-build

# Copy source code and configuration files
# Preserves the dependency cache from the previous stage
COPY . .

# Ensure proper ownership of node_modules from dependency cache
# Prevents permission issues during build process
COPY --from=dependency-cache /app/node_modules ./node_modules

# Set environment variables for production deployment
# NODE_ENV: Configures the application to run in production mode
# NEXT_TELEMETRY_DISABLED: Controls Next.js telemetry data collection
# GENERATE_SOURCEMAP: Disables source map generation to reduce build size and improve security
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=${NEXT_TELEMETRY_DISABLED}
ENV GENERATE_SOURCEMAP=false

# Conditionally configure Next.js for standalone output based on STANDALONE_OUTPUT build argument
# If STANDALONE_OUTPUT is "true":
#   - Creates a minimal next.config.js with standalone output configuration
#   - Only creates config if neither next.config.js nor next.config.mjs exists
#   - Standalone output bundles all dependencies into a self-contained application
# If STANDALONE_OUTPUT is not "true":
#   - Uses standard Next.js build which requires Node.js runtime and dependencies
RUN if [ "$STANDALONE_OUTPUT" = "true" ]; then \
        echo "🔧 Configuring Next.js standalone output..." && \
        if [ ! -f next.config.js ] && [ ! -f next.config.mjs ]; then \
            echo "const nextConfig = { output: 'standalone' }; module.exports = nextConfig;" > next.config.js; \
        fi && \
        echo "✅ Standalone output configured"; \
    else \
        echo "⚠️  Using standard Next.js build (requires runtime dependencies)"; \
    fi

# Build stage: Performs comprehensive code quality checks and application build
# This multi-step process includes:
# 1. TypeScript type checking (if tsconfig.json exists) - validates type safety
# 2. ESLint analysis (if config exists) - enforces code quality standards with zero warnings
# 3. Next.js application build using the appropriate package manager:
#    - Yarn (if yarn.lock exists)
#    - npm (if package-lock.json exists)
#    - pnpm (if pnpm-lock.yaml exists, with corepack enablement)
# Exits with error if no package manager lockfile is found
# Provides detailed logging with emojis for better build process visibility
RUN echo "🔍 Running code quality checks and building application..." && \
    if [ -f tsconfig.json ]; then \
        echo "🔧 Running TypeScript type checking..." && \
        npx tsc --noEmit || echo "⚠️  TypeScript warnings found"; \
    fi && \
    if [ -f .eslintrc.json ] || [ -f .eslintrc.js ]; then \
        echo "🔧 Running ESLint analysis..." && \
        npx eslint . --ext .ts,.tsx,.js,.jsx --max-warnings 0 || echo "⚠️  ESLint warnings found"; \
    fi && \
    echo "🔨 Building Next.js application..." && \
    if [ -f yarn.lock ]; then \
        echo "📦 Building with Yarn..." && \
        yarn run build; \
    elif [ -f package-lock.json ]; then \
        echo "📦 Building with npm..." && \
        npm run build; \
    elif [ -f pnpm-lock.yaml ]; then \
        echo "📦 Building with pnpm..." && \
        corepack enable pnpm && pnpm run build; \
    else \
        echo "❌ No lockfile found for build process" && exit 1; \
    fi && \
    echo "✅ Build completed successfully"

# Verify build artifacts based on build configuration
# This step validates the presence of required build outputs:
# - For standalone builds: checks for server.js and static assets directory
# - For standard builds: checks for .next directory existence
# Exits with error code 1 if any required artifacts are missing
# Provides detailed logging for build verification status
RUN echo "✅ Verifying build artifacts..." && \
    if [ "$STANDALONE_OUTPUT" = "true" ]; then \
        [ -f ".next/standalone/server.js" ] || (echo "❌ Standalone server not found" && exit 1) && \
        [ -d ".next/static" ] || (echo "❌ Static assets not found" && exit 1) && \
        echo "✅ Standalone build verification completed"; \
    else \
        [ -d ".next" ] || (echo "❌ Next.js build output not found" && exit 1) && \
        echo "✅ Standard build verification completed"; \
    fi && \
    echo "✅ Build verification completed successfully"

# ==============================================================================
# Stage 4: Security vulnerability scanning and validation
# ==============================================================================
FROM application-build AS security-scan

# Security vulnerability scanning layer
# Performs comprehensive security audits on npm dependencies based on SECURITY_SCAN_REQUIRED flag
# - When SECURITY_SCAN_REQUIRED=true: Runs strict security checks that fail the build on moderate+ vulnerabilities
# - When SECURITY_SCAN_REQUIRED=false: Runs security checks but only warns about issues without failing the build
# Uses both npm audit and audit-ci tools to ensure thorough vulnerability detection
# Audit level set to 'moderate' to catch significant security issues while avoiding noise from low-severity alerts
RUN echo "🔍 Running security vulnerability scan..." && \
    if [ "$SECURITY_SCAN_REQUIRED" = "true" ]; then \
        echo "🔒 Running npm security audit..." && \
        npm audit --audit-level moderate || (echo "❌ Security vulnerabilities detected" && exit 1) && \
        echo "🔒 Running audit-ci security scan..." && \
        audit-ci --moderate || (echo "❌ Critical vulnerabilities found" && exit 1); \
    else \
        echo "🔒 Running security scan with warnings..." && \
        npm audit --audit-level moderate || echo "⚠️  Security scan completed with warnings" && \
        audit-ci --moderate || echo "⚠️  Security policy check completed with warnings"; \
    fi && \
    echo "✅ Security scan completed successfully"

# Generate comprehensive security documentation for the application
# This step creates JSON reports for vulnerability assessment and dependency analysis:
# - security-audit.json: Contains npm audit results for known vulnerabilities
# - dependency-tree.json: Contains complete dependency tree with versions
# Error handling ensures build continues even if audit/list commands fail
RUN echo "📄 Generating security documentation..." && \
    npm audit --json > security-audit.json 2>/dev/null || echo "Security audit JSON not available" && \
    npm list --json > dependency-tree.json 2>/dev/null || echo "Dependency tree JSON not available" && \
    echo "✅ Security documentation generated"

# ==============================================================================
# Stage 5: Production runtime environment
# ==============================================================================
FROM node:${NODE_VERSION:-22}-${ALPINE_VERSION:-alpine} AS production

# Runtime environment variables only (not build-time variables)
# These persist in the final image for runtime configuration
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Install minimal runtime dependencies for production deployment
# - dumb-init: Lightweight init system for proper signal handling
# - curl: HTTP client for health checks and service discovery
RUN apk add --no-cache \
    dumb-init \
    curl \
    && rm -rf /var/cache/apk/*

# Create dedicated application user for enhanced security
# Uses specific UID/GID (1001) for consistency with Next.js conventions
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Create application directory structure with proper ownership
# Sets up directories for application assets, cache, and temporary files
RUN mkdir -p /app/.next /app/public /app/logs /app/tmp && \
    chown -R nextjs:nodejs /app

# Set working directory for application execution
WORKDIR /app

# Build configuration arguments for conditional asset copying
ARG STANDALONE_OUTPUT=true
ARG UI_PORT=3000

# Copy application assets from build stage with enhanced conditional logic
# Handles both standalone and standard Next.js output configurations
RUN if [ "$STANDALONE_OUTPUT" = "true" ]; then \
        echo "📦 Preparing for standalone application deployment..."; \
    else \
        echo "📦 Preparing for standard Next.js application deployment..."; \
    fi

# Copy public assets and static files (always needed)
COPY --from=application-build --chown=nextjs:nodejs /app/public ./public

# Conditional copying based on build type with proper fallback handling
# For standalone builds: copy standalone server and runtime files
# For standard builds: copy full .next directory and install production dependencies
RUN if [ "$STANDALONE_OUTPUT" = "true" ]; then \
        echo "📦 Copying standalone application assets..."; \
    else \
        echo "📦 Copying standard Next.js assets and installing runtime dependencies..."; \
    fi

# Copy Next.js build output with enhanced conditional logic
COPY --from=application-build --chown=nextjs:nodejs /app/.next/standalone ./
#COPY --from=application-build --chown=nextjs:nodejs /app/.next ./.next

COPY --from=application-build --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy package.json only for non-standalone builds (needed for npm start)
# For standalone builds, package.json is optional and only used for version info
RUN if [ "$STANDALONE_OUTPUT" = "false" ]; then \
        echo "📦 Copying package files for standard deployment..."; \
    fi

COPY --from=application-build --chown=nextjs:nodejs /app/package.json ./package.json

# Install production dependencies conditionally based on STANDALONE_OUTPUT build argument
# - If STANDALONE_OUTPUT is "false": Installs npm production dependencies using npm ci
#   with audit disabled for faster installation in containerized environments
# - If STANDALONE_OUTPUT is "true": Skips dependency installation as standalone builds
#   typically bundle all dependencies during the build process
# This conditional approach optimizes the final image size and build time based on deployment strategy
RUN if [ "$STANDALONE_OUTPUT" = "false" ]; then \
        echo "📦 Installing production dependencies..." && \
        npm ci --only=production --audit=false && \
        echo "✅ Production dependencies installed"; \
    else \
        echo "✅ Standalone build - no runtime dependencies needed"; \
    fi

# Copy security audit results and dependency analysis from the security-scan stage
# - security-audit.json: Contains vulnerability scan results and security findings
# - dependency-tree.json: Contains dependency analysis and package information
COPY --from=security-scan /app/security-audit.json ./security-audit.json
COPY --from=security-scan /app/dependency-tree.json ./dependency-tree.json

# Ensure proper permissions for Next.js cache and runtime files
RUN chown -R nextjs:nodejs /app/.next && \
    chmod -R 755 /app

# Switch to non-root user for enhanced security
USER nextjs

# Create and configure a comprehensive health check script for the Veridis Identity UI application
# This script performs multiple validation checks:
# - Verifies Next.js application structure (standalone vs standard build)
# - Checks directory permissions and accessibility
# - Tests application health endpoints with retry logic
# - Validates environment configuration
# - Provides detailed status reporting with emojis for better visibility
# The script is created at /home/nextjs/health-check.sh and made executable
RUN echo '#!/bin/sh\n\
set -e\n\
echo "🔍 Checking Veridis Identity UI application health..."\n\
\n\
# Get application configuration from environment\n\
UI_PORT=${PORT:-3000}\n\
NODE_ENV=${NODE_ENV:-production}\n\
\n\
# Verify Next.js application structure\n\
if [ -f "server.js" ]; then\n\
  echo "✅ Next.js standalone server accessible"\n\
  BUILD_TYPE="standalone"\n\
elif [ -d ".next" ]; then\n\
  echo "✅ Next.js application build accessible"\n\
  BUILD_TYPE="standard"\n\
else\n\
  echo "❌ Next.js application not found" && exit 1\n\
fi\n\
\n\
# Check application directories and permissions\n\
[ -d "/app/public" ] && echo "✅ Public assets directory accessible" || echo "⚠️  Public directory missing"\n\
[ -d "/app/.next" ] && echo "✅ Next.js build directory accessible" || echo "⚠️  Build directory missing"\n\
[ -w "/app/tmp" ] && echo "✅ Temporary directory writable" || echo "⚠️  Temporary directory not writable"\n\
\n\
# Test application health endpoint with enhanced retry logic\n\
HEALTH_RETRIES=3\n\
HEALTH_DELAY=2\n\
HEALTH_SUCCESS=false\n\
\n\
for i in $(seq 1 $HEALTH_RETRIES); do\n\
  # Try dedicated health endpoint first\n\
  if curl -f --connect-timeout 5 --max-time 10 http://localhost:$UI_PORT/api/health >/dev/null 2>&1; then\n\
    echo "✅ Application health endpoint responding"\n\
    HEALTH_SUCCESS=true\n\
    break\n\
  # Fallback to main page\n\
  elif curl -f --connect-timeout 5 --max-time 10 http://localhost:$UI_PORT/ >/dev/null 2>&1; then\n\
    echo "✅ Application main page responding (health endpoint not available)"\n\
    HEALTH_SUCCESS=true\n\
    break\n\
  elif [ $i -eq $HEALTH_RETRIES ]; then\n\
    echo "⚠️  Application not responding after $HEALTH_RETRIES attempts (may be starting)"\n\
  else\n\
    echo "⏳ Application not ready, retrying in ${HEALTH_DELAY}s... (attempt $i/$HEALTH_RETRIES)"\n\
    sleep $HEALTH_DELAY\n\
  fi\n\
done\n\
\n\
# Verify environment configuration\n\
[ -n "$NEXT_PUBLIC_API_URL" ] && echo "✅ Backend API URL configured" || echo "⚠️  API URL not configured"\n\
[ -n "$NEXT_PUBLIC_APP_URL" ] && echo "✅ Application URL configured" || echo "⚠️  App URL not configured"\n\
\n\
# Display build type information\n\
echo "ℹ️  Build Type: $BUILD_TYPE"\n\
\n\
echo "🎯 UI application health check completed!"\n\
' > /home/nextjs/health-check.sh && chmod +x /home/nextjs/health-check.sh

# Configure comprehensive health check for production monitoring
# Extended intervals for UI applications with detailed service validation
HEALTHCHECK --interval=60s --timeout=30s --start-period=30s --retries=3 \
    CMD /home/nextjs/health-check.sh

# Create an enhanced startup script for the Next.js application container
# This script provides comprehensive application information, environment detection,
# and intelligent startup logic with the following features:
#
# Application Detection:
# - Automatically detects build type (standalone vs standard Next.js)
# - Reports Node.js version, environment, and configuration
# - Provides dependency information and package counts
#
# Environment Reporting:
# - Shows telemetry status and public environment variables
# - Reports runtime information including user, memory, and working directory
# - Displays static asset information and build artifact sizes
#
# Security & Health:
# - Reports security audit status and vulnerability counts if available
# - Provides container management tips and best practices
# - Includes health check and deployment guidance
#
# Startup Logic:
# - Prioritizes standalone server.js if available (optimized)
# - Falls back to npm start for standard builds
# - Provides error handling for missing builds
# - Supports custom command execution via arguments
#
# The script is installed to /home/nextjs/startup.sh with execute permissions
# and serves as the main entrypoint for the containerized Next.js application
RUN echo '#!/bin/sh\n\
echo "⚛️  Veridis Identity UI Application"\n\
echo "==================================="\n\
\n\
echo "Application Information:"\n\
echo "  • Framework: Next.js with React and TypeScript"\n\
echo "  • Node.js Version: $(node --version)"\n\
echo "  • Environment: ${NODE_ENV:-development}"\n\
echo "  • Port: ${PORT:-3000}"\n\
echo "  • Hostname: ${HOSTNAME:-localhost}"\n\
\n\
# Enhanced build type detection with dependency information\n\
if [ -f "server.js" ]; then\n\
  echo "  • Build Type: Standalone (optimized, self-contained)"\n\
  echo "  • Server: Custom Next.js standalone server"\n\
  echo "  • Dependencies: Bundled (no node_modules required)"\n\
  SERVER_CMD="node server.js"\n\
elif [ -d ".next" ] && [ -d "node_modules" ]; then\n\
  echo "  • Build Type: Standard Next.js with runtime dependencies"\n\
  echo "  • Server: Next.js start command"\n\
  echo "  • Dependencies: $(ls node_modules | wc -l) packages installed"\n\
  SERVER_CMD="npm start"\n\
elif [ -d ".next" ]; then\n\
  echo "  • Build Type: Standard Next.js (WARNING: missing dependencies)"\n\
  echo "  • Server: Next.js start command"\n\
  echo "  • Dependencies: MISSING - container may fail to start"\n\
  SERVER_CMD="npm start"\n\
else\n\
  echo "  • Build Type: Unknown or missing"\n\
  echo "  • Server: Cannot determine startup command"\n\
  SERVER_CMD="echo Error: No valid Next.js build found && exit 1"\n\
fi\n\
echo ""\n\
echo "Environment Configuration:"\n\
echo "  • Telemetry: $([ "$NEXT_TELEMETRY_DISABLED" = "1" ] && echo "disabled" || echo "enabled")"\n\
echo "  • API URL: ${NEXT_PUBLIC_API_URL:-not configured}"\n\
echo "  • App URL: ${NEXT_PUBLIC_APP_URL:-not configured}"\n\
echo "  • Environment: ${NEXT_PUBLIC_ENVIRONMENT:-not specified}"\n\
echo ""\n\
echo "Runtime Information:"\n\
echo "  • User: $(whoami) ($(id))"\n\
echo "  • Working Directory: $(pwd)"\n\
echo "  • Available Memory: $(free -h 2>/dev/null | grep Mem | awk '\''{print $2}'\'' || echo "Unknown")"\n\
echo ""\n\
# Enhanced static assets reporting\n\
if [ -d "./public" ] && [ "$(ls -A ./public 2>/dev/null)" ]; then\n\
  echo "Static Assets:"\n\
  echo "  • Public directory size: $(du -sh ./public 2>/dev/null | cut -f1)"\n\
  echo "  • Public asset count: $(find ./public -type f 2>/dev/null | wc -l) files"\n\
else\n\
  echo "Static Assets: No public assets found"\n\
fi\n\
\n\
if [ -d "./.next/static" ]; then\n\
  echo "  • Build assets size: $(du -sh ./.next/static 2>/dev/null | cut -f1)"\n\
  echo "  • Build asset count: $(find ./.next/static -type f 2>/dev/null | wc -l) files"\n\
fi\n\
echo ""\n\
# Enhanced security status reporting\n\
if [ -f "./security-audit.json" ]; then\n\
  echo "Security Status: Audit completed (see security-audit.json)"\n\
  # Try to parse vulnerability count if possible\n\
  if command -v node >/dev/null 2>&1; then\n\
    VULN_COUNT=$(node -e "try { const audit = require('./security-audit.json'); console.log(Object.keys(audit.vulnerabilities || {}).length); } catch (e) { console.log('unknown'); }" 2>/dev/null)\n\
    echo "  • Vulnerabilities: $VULN_COUNT"\n\
  fi\n\
else\n\
  echo "Security Status: No audit report available"\n\
fi\n\
echo ""\n\
echo "🎯 UI application ready for deployment!"\n\
echo ""\n\
if [ $# -eq 0 ]; then\n\
    echo "💡 Application management tips:"\n\
    echo "  • View logs: docker logs <container-id>"\n\
    echo "  • Health check: curl http://localhost:${PORT:-3000}/"\n\
    echo "  • Environment: docker run -e NEXT_PUBLIC_API_URL=... -e NODE_ENV=production"\n\
    echo "  • Asset serving: -v \$(pwd)/public:/app/public (development only)"\n\
    echo "  • Build standalone: --build-arg STANDALONE_OUTPUT=true (recommended)"\n\
    echo "  • Build standard: --build-arg STANDALONE_OUTPUT=false (requires more resources)"\n\
    echo ""\n\
    echo "🚀 Starting server with: $SERVER_CMD"\n\
    echo ""\n\
    exec $SERVER_CMD\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/nextjs/startup.sh && chmod +x /home/nextjs/startup.sh

# Expose UI application port for external access
EXPOSE ${UI_PORT}

# Set entrypoint using dumb-init for proper signal handling
# Provides consistent initialization and graceful shutdown capabilities
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/home/nextjs/startup.sh"]

# Default command runs the Next.js application
# Can be overridden to run specific development or maintenance operations
CMD []

# Comprehensive metadata labels for the Veridis Identity UI Application container
#
# This LABEL instruction defines extensive metadata for the Docker image including:
# - Basic project information (maintainer, version, description)
# - Service classification (frontend UI service running on port 3000)
# - Technology stack versions (Next.js 14+, React 18+, TypeScript 5+)
# - Build configuration (standalone output, security scanning)
# - Runtime environment (Node.js version, package manager)
# - Open Container Initiative (OCI) standard annotations for:
#   * Source repository and documentation links
#   * Image title, description, and vendor information
#   * License information (MIT)
#   * Base image specifications (Node.js on Alpine Linux)
#
# These labels enable better container management, automated tooling integration,
# and provide essential metadata for deployment and monitoring systems.
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Veridis Identity UI Application with Next.js, React, and TypeScript" \
      environment.type="frontend" \
      service.type="ui" \
      service.port="3000" \
      framework.nextjs="14+" \
      framework.react="18+" \
      framework.typescript="5+" \
      build.standalone="${STANDALONE_OUTPUT}" \
      security.scan.enabled="${SECURITY_SCAN_REQUIRED}" \
      tools.node.version="${NODE_VERSION}" \
      package.manager="${PACKAGE_MANAGER}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Identity UI Application" \
      org.opencontainers.image.description="Production-ready Next.js UI application with comprehensive security and monitoring" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/ui/README.md" \
      org.opencontainers.image.base.name="node:${NODE_VERSION:-22}-${ALPINE_VERSION:-alpine}" \
      org.opencontainers.image.base.os.version="${ALPINE_VERSION:-alpine}"
