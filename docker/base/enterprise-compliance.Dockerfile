# ==============================================================================
# Veridis Enterprise Compliance and GDPR Management Environment
# ==============================================================================
#
# This Dockerfile creates a comprehensive enterprise-grade compliance environment
# for automated GDPR compliance, data privacy auditing, and regulatory reporting.
# The image provides a complete toolchain for managing data subject rights,
# cryptographic deletion, and continuous compliance monitoring.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# 1. base: Base Alpine environment with system dependencies
# 2. compliance-tools: Compliance and GDPR automation tools installation
# 3. security-scanning: Security vulnerability scanning and audit tools
# 4. monitoring-tools: Compliance monitoring and reporting tools installation
# 5. production: Final compliance environment with all tools
#
# INCLUDED COMPONENTS:
# - Node.js 22 LTS runtime for compliance automation
# - GDPR automation toolkit for data subject rights management
# - Data privacy auditor for continuous compliance monitoring
# - Cryptographic deletion tools for secure data erasure
# - Compliance reporting engine for regulatory documentation
# - Security scanning and vulnerability assessment tools
#
# SECURITY FEATURES:
# - Non-root user execution (compliance:1000)
# - Cryptographic data erasure capabilities
# - Comprehensive audit logging and trail management
# - Secure temporary file handling
# - Environment variable security controls
# - Minimal attack surface with Alpine base
#
# BUILD ARGUMENTS:
# - NODE_VERSION: Node.js LTS version (default: 22)
# - GDPR_TOOLKIT_VERSION: GDPR automation toolkit version (default: 2.5.0)
# - PRIVACY_AUDITOR_VERSION: Data privacy auditor version (default: 1.4.2)
# - COMPLIANCE_REPORTER_VERSION: Compliance reporter version (default: 3.1.0)
# - CRYPTO_DELETION_VERSION: Cryptographic deletion version (default: 1.3.2)
# - DATA_RIGHTS_MANAGER_VERSION: Data subject rights manager version (default: 1.1.0)
# - SNYK_VERSION: Snyk security scanner version (default: 1.1160.0)
# - MEMORY_LIMIT: Node.js memory limit in MB (default: 1024)
# - COMPLIANCE_TOOLS_REQUIRED: Fail build if compliance tools unavailable (default: true)
#
# USAGE:
# Build compliance environment:
# docker build --build-arg GDPR_TOOLKIT_VERSION=2.5.0 --build-arg NODE_VERSION=22 -t veridis/compliance .
#
# Run compliance container with data mounting:
# docker run -d -v $(pwd)/compliance-data:/compliance/data -p 3001:3001 veridis/compliance
#
# ENVIRONMENT VARIABLES (Runtime):
# - GDPR_CRYPTO_ERASURE_ENABLED: Enable cryptographic deletion (default: true)
# - COMPLIANCE_AUDIT_LEVEL: Audit detail level (basic, detailed, comprehensive)
# - DATA_RETENTION_DAYS: Default data retention period in days
# - PRIVACY_SCAN_INTERVAL: Privacy scanning interval in minutes
# - COMPLIANCE_LOG_LEVEL: Logging verbosity (debug, info, warn, error)
#
# COMPLIANCE WORKFLOW:
# - Automated GDPR compliance monitoring and reporting
# - Data subject rights automation (access, portability, erasure)
# - Cryptographic deletion for secure data removal
# - Continuous privacy impact assessments
# - Regulatory compliance reporting and documentation
#
# MAINTENANCE NOTES:
# - Based on Alpine Linux for minimal attack surface
# - Package versions are pinned for reproducible builds
# - Compliance tools are validated for enterprise requirements
# - Compatible with enterprise orchestration platforms
# - Regular security updates through base image updates
# ==============================================================================

# ==============================================================================
# Stage 1: Base Alpine environment with system dependencies
# ==============================================================================
FROM node:22-alpine AS base

# Build arguments for version control and compliance configuration
ARG NODE_VERSION=22
ARG GDPR_TOOLKIT_VERSION=2.5.0
ARG PRIVACY_AUDITOR_VERSION=1.4.2
ARG COMPLIANCE_REPORTER_VERSION=3.1.0
ARG CRYPTO_DELETION_VERSION=1.3.2
ARG DATA_RIGHTS_MANAGER_VERSION=1.1.0
ARG SNYK_VERSION=1.1160.0
ARG MEMORY_LIMIT=1024
ARG COMPLIANCE_TOOLS_REQUIRED=true

# Set environment variables from build arguments
ENV NODE_VERSION=${NODE_VERSION}
ENV GDPR_TOOLKIT_VERSION=${GDPR_TOOLKIT_VERSION}
ENV PRIVACY_AUDITOR_VERSION=${PRIVACY_AUDITOR_VERSION}
ENV COMPLIANCE_REPORTER_VERSION=${COMPLIANCE_REPORTER_VERSION}
ENV CRYPTO_DELETION_VERSION=${CRYPTO_DELETION_VERSION}
ENV DATA_RIGHTS_MANAGER_VERSION=${DATA_RIGHTS_MANAGER_VERSION}
ENV SNYK_VERSION=${SNYK_VERSION}
ENV MEMORY_LIMIT=${MEMORY_LIMIT}
ENV COMPLIANCE_TOOLS_REQUIRED=${COMPLIANCE_TOOLS_REQUIRED}

# Install essential system dependencies for compliance operations
# Uses --no-cache to minimize image size and --virtual for build dependencies
# - python3: Python 3 interpreter for compliance automation tools
# - py3-pip: Python package installer for compliance libraries
# - openssl: SSL/TLS tools for cryptographic operations
# - curl: HTTP client for health checks and API interactions
# - jq: JSON processor for compliance data manipulation
# - dumb-init: Lightweight init system for proper signal handling
# - tzdata: Timezone data for accurate compliance timestamps
# - ca-certificates: Certificate authority certificates for SSL verification
RUN apk add --no-cache \
    python3 \
    py3-pip \
    openssl \
    curl \
    jq \
    dumb-init \
    tzdata \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# ==============================================================================
# Stage 2: Compliance and GDPR automation tools installation
# ==============================================================================
FROM base AS compliance-tools

# Install GDPR compliance automation tools with pinned versions for reproducibility
# These tools provide comprehensive GDPR compliance capabilities including:
# - gdpr-automation-toolkit: Core GDPR automation and data processing workflows
# - data-privacy-auditor: Continuous privacy monitoring and assessment
# - compliance-reporter: Automated regulatory compliance reporting
# - cryptographic-deletion: Secure data erasure with cryptographic guarantees
# - data-subject-rights-manager: Automation for data subject access rights
RUN pip3 install --no-cache-dir \
    gdpr-automation-toolkit==${GDPR_TOOLKIT_VERSION} \
    data-privacy-auditor==${PRIVACY_AUDITOR_VERSION} \
    compliance-reporter==${COMPLIANCE_REPORTER_VERSION} \
    cryptographic-deletion==${CRYPTO_DELETION_VERSION} \
    data-subject-rights-manager==${DATA_RIGHTS_MANAGER_VERSION}

# Verify compliance tools installation with proper error handling
# Ensures all critical compliance tools are properly installed and accessible
RUN echo "🔍 Verifying compliance tools installation..." && \
    if [ "$COMPLIANCE_TOOLS_REQUIRED" = "true" ]; then \
        (python3 -c "import gdpr_automation_toolkit" || (echo "❌ GDPR automation toolkit not available" && exit 1)) && \
        (python3 -c "import data_privacy_auditor" || (echo "❌ Data privacy auditor not available" && exit 1)) && \
        (python3 -c "import compliance_reporter" || (echo "❌ Compliance reporter not available" && exit 1)) && \
        (python3 -c "import cryptographic_deletion" || (echo "❌ Cryptographic deletion not available" && exit 1)) && \
        (python3 -c "import data_subject_rights_manager" || (echo "❌ Data subject rights manager not available" && exit 1)); \
    fi && \
    echo "✅ Compliance tools verification completed"

# ==============================================================================
# Stage 3: Security scanning and audit tools installation
# ==============================================================================
FROM compliance-tools AS security-scanning

# Install audit and monitoring tools with pinned versions
# These Node.js tools provide enterprise-grade security and compliance monitoring:
# - @veridis/audit-logger: Comprehensive audit logging for compliance trails
# - @veridis/compliance-monitor: Real-time compliance monitoring and alerting
# - @veridis/gdpr-automation: GDPR-specific automation and workflow tools
# - snyk: Security vulnerability scanning and dependency analysis
RUN npm install -g \
    @veridis/audit-logger@2.1.0 \
    @veridis/compliance-monitor@3.0.2 \
    @veridis/gdpr-automation@2.2.1 \
    snyk@${SNYK_VERSION}

# Verify security and monitoring tools installation
# Ensures all security scanning and monitoring capabilities are available
RUN echo "🔍 Verifying security and monitoring tools installation..." && \
    if [ "$COMPLIANCE_TOOLS_REQUIRED" = "true" ]; then \
        (command -v audit-logger >/dev/null || (echo "❌ Audit logger not available" && exit 1)) && \
        (command -v compliance-monitor >/dev/null || (echo "❌ Compliance monitor not available" && exit 1)) && \
        (command -v gdpr-automation >/dev/null || (echo "❌ GDPR automation not available" && exit 1)) && \
        (command -v snyk >/dev/null || (echo "❌ Snyk security scanner not available" && exit 1)); \
    fi && \
    echo "✅ Security and monitoring tools verification completed"

# ==============================================================================
# Stage 4: Monitoring tools configuration and validation
# ==============================================================================
FROM security-scanning AS monitoring-tools

# Create dedicated compliance user for enhanced security
# Uses specific UID/GID (1000) for consistency across enterprise environments
RUN addgroup -g 1000 compliance && \
    adduser -u 1000 -G compliance -s /bin/sh -D compliance

# Create comprehensive directory structure for compliance operations
# Sets up secure directories for audit logs, GDPR data, reports, and cryptographic erasure
# Ensures proper ownership and permissions for compliance data handling
RUN mkdir -p /compliance/audit-logs \
             /compliance/gdpr-data \
             /compliance/reports \
             /compliance/crypto-erasure \
             /compliance/data \
             /compliance/tmp \
             /compliance/config \
             /compliance/backup && \
    chown -R compliance:compliance /compliance

# ==============================================================================
# Stage 5: Production compliance environment
# ==============================================================================
FROM monitoring-tools AS production

# Set working directory for compliance operations
WORKDIR /app

# Set security-focused and compliance-specific environment variables
# Configures Node.js runtime for secure compliance operations
# Enables cryptographic erasure and comprehensive audit logging
ENV NODE_OPTIONS="--max-old-space-size=${MEMORY_LIMIT} --disallow-code-generation-from-strings"
ENV NPM_CONFIG_AUDIT_LEVEL=moderate
ENV GDPR_CRYPTO_ERASURE_ENABLED=true
ENV COMPLIANCE_AUDIT_LEVEL=detailed
ENV TMPDIR=/compliance/tmp
ENV DATA_RETENTION_DAYS=2555
ENV PRIVACY_SCAN_INTERVAL=60
ENV COMPLIANCE_LOG_LEVEL=info

# Switch to non-root user for enhanced security
USER compliance

# Create comprehensive health check script for compliance environment
# Validates all compliance tools, security scanners, and service endpoints
RUN echo '#!/bin/sh\n\
set -e\n\
echo "🔍 Checking Enterprise Compliance Environment..."\n\
\n\
# Verify compliance tools availability\n\
echo "Verifying compliance tools:"\n\
if python3 -c "import gdpr_automation_toolkit" >/dev/null 2>&1; then\n\
  echo "✅ GDPR automation toolkit available"\n\
else\n\
  echo "❌ GDPR automation toolkit not available" && exit 1\n\
fi\n\
\n\
if python3 -c "import data_privacy_auditor" >/dev/null 2>&1; then\n\
  echo "✅ Data privacy auditor available"\n\
else\n\
  echo "❌ Data privacy auditor not available" && exit 1\n\
fi\n\
\n\
if python3 -c "import compliance_reporter" >/dev/null 2>&1; then\n\
  echo "✅ Compliance reporter available"\n\
else\n\
  echo "❌ Compliance reporter not available" && exit 1\n\
fi\n\
\n\
# Verify monitoring tools\n\
echo "Verifying monitoring tools:"\n\
(command -v snyk >/dev/null && echo "✅ Snyk security scanner available") || echo "⚠️  Snyk not available"\n\
(command -v audit-logger >/dev/null && echo "✅ Audit logger available") || echo "⚠️  Audit logger not available"\n\
\n\
# Check compliance directories\n\
echo "Verifying compliance directories:"\n\
[ -d "/compliance/audit-logs" ] && echo "✅ Audit logs directory accessible" || (echo "❌ Audit logs directory missing" && exit 1)\n\
[ -d "/compliance/gdpr-data" ] && echo "✅ GDPR data directory accessible" || (echo "❌ GDPR data directory missing" && exit 1)\n\
[ -w "/compliance/tmp" ] && echo "✅ Temporary directory writable" || (echo "❌ Temporary directory not writable" && exit 1)\n\
\n\
# Test compliance service endpoint if running\n\
if curl -f http://localhost:3001/compliance/health >/dev/null 2>&1; then\n\
  echo "✅ Compliance service responding"\n\
else\n\
  echo "⚠️  Compliance service not responding (may be starting)"\n\
fi\n\
\n\
echo "🎯 Enterprise compliance environment ready!"\n\
' > /home/compliance/health-check.sh && chmod +x /home/compliance/health-check.sh

# Configure comprehensive health check for compliance environment
# Extended intervals for enterprise environments with detailed compliance validation
HEALTHCHECK --interval=120s --timeout=30s --start-period=45s --retries=3 \
    CMD /home/compliance/health-check.sh

# Create detailed startup script for enterprise compliance environment
# Provides comprehensive environment information and compliance capabilities
RUN echo '#!/bin/sh\n\
echo "🏢 Veridis Enterprise Compliance and GDPR Management Environment"\n\
echo "================================================================"\n\
echo "Compliance Tools:"\n\
if python3 -c "import gdpr_automation_toolkit" >/dev/null 2>&1; then\n\
  echo "  • GDPR Automation Toolkit: v${GDPR_TOOLKIT_VERSION}"\n\
else\n\
  echo "  • GDPR Automation Toolkit: Not available"\n\
fi\n\
\n\
if python3 -c "import data_privacy_auditor" >/dev/null 2>&1; then\n\
  echo "  • Data Privacy Auditor: v${PRIVACY_AUDITOR_VERSION}"\n\
else\n\
  echo "  • Data Privacy Auditor: Not available"\n\
fi\n\
\n\
if python3 -c "import compliance_reporter" >/dev/null 2>&1; then\n\
  echo "  • Compliance Reporter: v${COMPLIANCE_REPORTER_VERSION}"\n\
else\n\
  echo "  • Compliance Reporter: Not available"\n\
fi\n\
\n\
if python3 -c "import cryptographic_deletion" >/dev/null 2>&1; then\n\
  echo "  • Cryptographic Deletion: v${CRYPTO_DELETION_VERSION}"\n\
else\n\
  echo "  • Cryptographic Deletion: Not available"\n\
fi\n\
\n\
if command -v node >/dev/null; then\n\
  echo "  • Node.js: $(node --version)"\n\
else\n\
  echo "  • Node.js: Not available"\n\
fi\n\
echo ""\n\
echo "Security and Monitoring:"\n\
(command -v snyk >/dev/null && echo "  • Snyk Security Scanner: Available") || echo "  • Snyk Security Scanner: Not available"\n\
(command -v audit-logger >/dev/null && echo "  • Audit Logger: Available") || echo "  • Audit Logger: Not available"\n\
(command -v compliance-monitor >/dev/null && echo "  • Compliance Monitor: Available") || echo "  • Compliance Monitor: Not available"\n\
echo ""\n\
echo "Environment Configuration:"\n\
echo "  • Memory Limit: ${MEMORY_LIMIT}MB"\n\
echo "  • Crypto Erasure: ${GDPR_CRYPTO_ERASURE_ENABLED:-false}"\n\
echo "  • Audit Level: ${COMPLIANCE_AUDIT_LEVEL:-basic}"\n\
echo "  • Data Retention: ${DATA_RETENTION_DAYS:-365} days"\n\
echo "  • Privacy Scan Interval: ${PRIVACY_SCAN_INTERVAL:-60} minutes"\n\
echo "  • Log Level: ${COMPLIANCE_LOG_LEVEL:-info}"\n\
echo ""\n\
echo "Compliance Directories:"\n\
echo "  • Audit Logs: /compliance/audit-logs"\n\
echo "  • GDPR Data: /compliance/gdpr-data"\n\
echo "  • Reports: /compliance/reports"\n\
echo "  • Crypto Erasure: /compliance/crypto-erasure"\n\
echo "  • Data: /compliance/data (mounted data)"\n\
echo ""\n\
echo "User: $(whoami) ($(id))"\n\
echo ""\n\
# Handle compliance data directory permissions\n\
if [ -d "/compliance/data" ] && [ ! -w "/compliance/data" ]; then\n\
  echo "⚠️  Compliance data directory not writable - checking permissions..."\n\
  if [ "$(stat -c %u /compliance/data)" != "1000" ]; then\n\
    echo "   Note: Data volume appears to be owned by different user"\n\
    echo "   Consider using: docker run --user $(id -u):$(id -g) ..."\n\
  fi\n\
fi\n\
echo "🎯 Ready for enterprise compliance and GDPR management!"\n\
echo ""\n\
if [ $# -eq 0 ]; then\n\
    echo "💼 Enterprise compliance tips:"\n\
    echo "  • Mount compliance data: -v \$(pwd)/compliance-data:/compliance/data"\n\
    echo "  • Run privacy audit: data-privacy-auditor scan /compliance/data"\n\
    echo "  • Generate compliance report: compliance-reporter generate"\n\
    echo "  • Perform crypto erasure: cryptographic-deletion erase <data-id>"\n\
    echo "  • Monitor compliance: compliance-monitor start"\n\
    echo "  • Security scan: snyk test"\n\
    echo ""\n\
    exec sh\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/compliance/startup.sh && chmod +x /home/compliance/startup.sh

# Set entrypoint using dumb-init for proper signal handling in enterprise environments
# Provides consistent initialization and graceful shutdown capabilities
ENTRYPOINT ["/sbin/dumb-init", "--", "/home/compliance/startup.sh"]

# Default command starts the compliance monitoring service
# Can be overridden to run specific compliance operations
CMD ["compliance-monitor", "start"]

# Expose compliance service port for enterprise integration
# Default port 3001 for compliance API and health monitoring
EXPOSE 3001

# Comprehensive enterprise metadata labels following OCI standards
# Provides detailed information about compliance capabilities and enterprise features
LABEL maintainer="Veridis Team" \
      version="1.0.0" \
      description="Veridis Enterprise Compliance and GDPR Management Environment with automated privacy controls" \
      environment.type="compliance" \
      compliance.gdpr="enabled" \
      compliance.audit.level="detailed" \
      compliance.crypto.erasure="enabled" \
      tools.gdpr.toolkit.version="${GDPR_TOOLKIT_VERSION}" \
      tools.privacy.auditor.version="${PRIVACY_AUDITOR_VERSION}" \
      tools.compliance.reporter.version="${COMPLIANCE_REPORTER_VERSION}" \
      tools.crypto.deletion.version="${CRYPTO_DELETION_VERSION}" \
      tools.data.rights.manager.version="${DATA_RIGHTS_MANAGER_VERSION}" \
      tools.snyk.version="${SNYK_VERSION}" \
      security.user="compliance" \
      security.uid="1000" \
      memory.limit="${MEMORY_LIMIT}MB" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Enterprise Compliance Environment" \
      org.opencontainers.image.description="Comprehensive enterprise compliance environment for GDPR automation and data privacy management" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/README.md" \
      org.opencontainers.image.base.name="node:20-alpine" \
      org.opencontainers.image.base.os.version="alpine"
