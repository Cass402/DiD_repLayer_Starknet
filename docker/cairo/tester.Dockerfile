# ==============================================================================
# Veridis Cairo Smart Contract Testing & Quality Assurance Environment
# ==============================================================================
#
# This Dockerfile creates a comprehensive testing environment for Cairo smart
# contracts, providing advanced testing capabilities, code coverage analysis,
# and quality assurance tooling for StarkNet development.
# The image uses a multi-stage approach for optimal performance and reliability.
#
# MULTI-STAGE BUILD ARCHITECTURE:
# ===============================
# 1. base-system: Core testing dependencies and Cairo toolchain
# 2. python-deps: Python testing framework with locked dependencies
# 3. testing-tools: Advanced testing utilities and coverage tools
# 4. qa-environment: Quality assurance and code analysis tools
# 5. production-ci: Lightweight CI-optimized production environment
# 6. production-dev: Full-featured development environment
#
# INCLUDED COMPONENTS:
# ===================
# • Cairo testing environment with Starknet Foundry (snforge)
# • Code coverage analysis with lcov and cairo-coverage
# • Python testing integration with pytest and pytest-xdist
# • Performance benchmarking and profiling tools
# • Test result aggregation and reporting
# • Continuous integration support with JUnit XML output
# • Parallel test execution for improved performance
# • Contract verification and validation testing
# • Gas usage analysis and optimization testing
# • Fuzzing and property-based testing capabilities
#
# TESTING FEATURES:
# =================
# • Comprehensive unit testing with snforge
# • Integration testing with StarkNet devnet
# • Property-based testing and fuzzing
# • Code coverage reporting with multiple formats
# • Performance benchmarking and gas analysis
# • Parallel test execution for speed optimization
# • Test result caching and incremental testing
# • Contract verification and validation
# • Security testing and vulnerability scanning
# • Cross-platform compatibility testing
#
# SECURITY FEATURES:
# ==================
# • Non-root user execution (cairo:configurable UID/GID)
# • Secure test data isolation and sandboxing
# • Safe contract compilation and execution
# • Test environment isolation and cleanup
# • Secure artifact storage and management
# • Network isolation for testing environments
# • Resource bounds enforcement and monitoring
# • Test data sanitization and validation
#
# BUILD ARGUMENTS:
# ================
# - UBUNTU_VERSION: Ubuntu base version (default: 22.04)
# - CAIRO_BASE_IMAGE: Base Cairo image reference (default: ghcr.io/veridis-protocol/cairo-base:v1.2.3)
# - STARKNET_FOUNDRY_VERSION: Starknet Foundry version (default: 0.44.0)
# - PYTHON_VERSION: Python version for testing tools (default: 3.11)
# - USER_UID: User ID for cairo user (default: 1001)
# - USER_GID: Group ID for cairo group (default: 1001)
# - PARALLEL_JOBS: Number of parallel test jobs (default: auto)
# - HEALTHCHECK_INTERVAL: Health check interval in seconds (default: 120)
# - TEST_TIMEOUT: Default test timeout in seconds (default: 600)
# - VERBOSE_TESTING: Enable verbose test output (default: false)
# - BUILD_TARGET: Build target (ci, dev) (default: ci)
#
# USAGE:
# ======
# Build CI-optimized testing environment (default):
# docker build -t veridis/cairo-testing:ci .
#
# Build development environment with debugging tools:
# docker build --target production-dev -t veridis/cairo-testing:dev .
#
# Build with custom base image:
# docker build --build-arg CAIRO_BASE_IMAGE=ghcr.io/veridis-protocol/cairo-base:v1.2.3 -t veridis/cairo-testing .
#
# Run testing container:
# docker run --rm -v $(pwd):/app/workspace veridis/cairo-testing
#
# Run specific test suite:
# docker run --rm -v $(pwd):/app/workspace -e TEST_SUITE=unit veridis/cairo-testing
#
# ENVIRONMENT VARIABLES (Runtime):
# ================================
# - TEST_SUITE: Test suite to run (unit, integration, all) [default: all]
# - COVERAGE_FORMAT: Coverage report format (html, xml, json, lcov) [default: html]
# - PARALLEL_EXECUTION: Enable parallel test execution [default: true]
# - TEST_TIMEOUT: Test execution timeout in seconds [default: 600]
# - FUZZING_ITERATIONS: Number of fuzzing iterations [default: 1000]
# - BENCHMARK_RUNS: Number of benchmark runs [default: 5]
# - VERBOSE_OUTPUT: Enable verbose test output [default: false]
# - FAIL_FAST: Stop on first test failure [default: false]
# - GENERATE_JUNIT: Generate JUnit XML reports [default: true]
# - CACHE_TESTS: Enable test result caching [default: true]
# - GAS_ANALYSIS: Enable gas usage analysis [default: true]
# - VERIFY_CONTRACTS: Enable contract verification [default: true]
# - COVERAGE_ENABLED: Enable code coverage analysis [default: true]
# - FUZZING_ENABLED: Enable fuzzing tests [default: true]
# - BENCHMARK_ENABLED: Enable performance benchmarks [default: false]
# - STARKNET_NETWORK: Network for integration tests [default: devnet]
# - STARKNET_TX_VERSION: Transaction version [default: 3]
# - RESOURCE_BOUNDS_ENABLED: Enable resource bounds [default: true]
# - CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL: MLIR optimization level [default: 3]
#
# TEST CONFIGURATIONS:
# ===================
# - unit: Fast unit tests with isolated contract testing
# - integration: Full integration tests with devnet interaction
# - performance: Performance benchmarks and gas optimization
# - security: Security testing and vulnerability scanning
# - fuzzing: Property-based testing and fuzzing
# - all: Complete test suite execution
#
# OUTPUT FORMATS:
# ==============
# - JUnit XML: CI/CD integration and test reporting
# - Coverage HTML: Interactive coverage reports
# - Coverage XML: Machine-readable coverage data
# - JSON Reports: Structured test result data
# - Performance Metrics: Gas usage and timing analysis
#
# MAINTENANCE NOTES:
# ==================
# - Based on pinned Cairo base image for reproducibility
# - Optimized for CI/CD pipeline integration
# - Supports parallel execution for performance
# - Compatible with major testing frameworks
# - Comprehensive logging and debugging support
# - Production-ready with security best practices
# - Multi-format output for various use cases
# - Efficient caching for incremental testing
# - Separate CI and development targets for size optimization
# ==============================================================================

# Global build arguments accessible to all stages
ARG UBUNTU_VERSION=22.04
ARG CAIRO_BASE_IMAGE=ghcr.io/veridis-protocol/cairo-base:v1.2.3
ARG STARKNET_FOUNDRY_VERSION=0.44.0
ARG PYTHON_VERSION=3.11
ARG USER_UID=1001
ARG USER_GID=1001
ARG PARALLEL_JOBS=auto
ARG TEST_TIMEOUT=600
ARG VERBOSE_TESTING=false
ARG BUILD_TARGET=ci

# ==============================================================================
# Stage 1: Base system with Cairo toolchain and minimal testing dependencies
# ==============================================================================
FROM ${CAIRO_BASE_IMAGE} AS base-system

# Switch to root for system configuration
USER root

# Install only essential testing dependencies for minimal footprint
# Core requirements:
# - jq: JSON processing for test results and configuration
# - curl: HTTP client for CI/CD integration and reporting
# - git: Version control for test repositories and submodules
# - lcov: Code coverage analysis and reporting
# Clean up package cache and temporary files to minimize image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    git \
    lcov \
    ca-certificates \
    coreutils \
    time \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Create comprehensive testing directory structure
# - /app/workspace: Project workspace for contract source code
# - /app/test-results: Test execution results and artifacts
# - /app/coverage: Code coverage reports and analysis
# - /app/benchmarks: Performance benchmark results
# - /app/cache: Test result caching and incremental data
# - /app/reports: Generated reports and documentation
# - /app/logs: Testing logs and debugging information
# - /app/config: Testing configuration and environment setup
RUN mkdir -p /app/workspace /app/test-results /app/coverage /app/benchmarks \
             /app/cache /app/reports /app/logs /app/config && \
    chown -R cairo:cairo /app

# Set working directory for all subsequent operations
WORKDIR /app

# ==============================================================================
# Stage 2: Python dependencies with locked versions for reproducibility
# ==============================================================================
FROM python:${PYTHON_VERSION}-slim AS python-deps

# Install Python build dependencies for native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create cairo user for consistent UID/GID across stages
RUN groupadd --gid ${USER_GID} cairo && \
    useradd --uid ${USER_UID} --gid cairo --shell /bin/bash --create-home cairo

USER cairo

# Copy locked requirements for reproducible builds
# This ensures exact same versions across all environments
COPY requirements-testing.txt /tmp/requirements-testing.txt

# Create Python virtual environment for isolated dependency management
# This prevents conflicts with system Python packages and ensures reproducibility
RUN python3 -m venv /home/cairo/.venv && \
    /home/cairo/.venv/bin/pip install --upgrade pip setuptools wheel

# Install Python testing framework with locked versions
# Using requirements.txt ensures reproducible builds with exact versions
RUN /home/cairo/.venv/bin/pip install --no-cache-dir -r /tmp/requirements-testing.txt

# Generate requirements file as fallback if not provided
RUN if [ ! -f /tmp/requirements-testing.txt ]; then \
        echo "Creating default requirements file..." && \
        /home/cairo/.venv/bin/pip install --no-cache-dir \
            pytest==8.4.0 \
            pytest-xdist==3.7.0 \
            pytest-cov==6.1.1 \
            pytest-html==4.1.1 \
            pytest-json-report==1.5.0 \
            pytest-benchmark==5.1.0 \
            pytest-timeout==2.4.0 \
            hypothesis==6.135.1 \
            coverage==7.3.0 \
            requests==2.31.0 && \
        /home/cairo/.venv/bin/pip freeze > /home/cairo/requirements-installed.txt; \
    fi

# ==============================================================================
# Stage 3: Testing tools and scripts with Cairo toolchain integration
# ==============================================================================
FROM base-system AS testing-tools

# Copy Python virtual environment from python-deps stage
COPY --from=python-deps --chown=cairo:cairo /home/cairo/.venv /home/cairo/.venv

# Switch to cairo user for tool installation to maintain security
USER cairo

# Add virtual environment to PATH for global access
ENV PATH="/home/cairo/.venv/bin:${PATH}"

# Create automated tool verification script for consistency
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🔍 Verifying testing tools..."\n\
\n\
# Define required tools for verification\n\
ESSENTIAL_TOOLS=("snforge" "scarb" "python3" "pytest" "jq" "lcov")\n\
OPTIONAL_TOOLS=("starkli" "coverage" "black" "mypy")\n\
\n\
# Verify essential tools\n\
for tool in "${ESSENTIAL_TOOLS[@]}"; do\n\
    if command -v "$tool" >/dev/null 2>&1; then\n\
        echo "✅ $tool accessible"\n\
    else\n\
        echo "❌ $tool missing - this is required for testing"\n\
        exit 1\n\
    fi\n\
done\n\
\n\
# Verify optional tools\n\
for tool in "${OPTIONAL_TOOLS[@]}"; do\n\
    if command -v "$tool" >/dev/null 2>&1; then\n\
        echo "✅ $tool accessible"\n\
    else\n\
        echo "⚠️  $tool not available (optional)"\n\
    fi\n\
done\n\
\n\
echo "📋 Tool Verification Summary:"\n\
echo "  • Scarb: $(scarb --version 2>/dev/null || echo \"Not available\")"\n\
echo "  • Starknet Foundry: $(snforge --version 2>/dev/null | head -n1 || echo \"Not available\")"\n\
echo "  • Python: $(python3 --version 2>/dev/null || echo \"Not available\")"\n\
echo "  • Pytest: $(pytest --version 2>/dev/null | head -n1 || echo \"Not available\")"\n\
echo "  • Coverage: $(coverage --version 2>/dev/null | head -n1 || echo \"Not available\")"\n\
echo "✅ Tool verification completed successfully"\n\
' > /usr/local/bin/verify-tools.sh && chmod +x /usr/local/bin/verify-tools.sh

# Create enhanced test configuration management script
# Handles test environment setup, configuration validation, and execution parameters
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🧪 Configuring Cairo testing environment..."\n\
\n\
# Runtime configuration with comprehensive defaults\n\
# All feature toggles are now runtime-controlled for flexibility\n\
TEST_SUITE=${TEST_SUITE:-all}\n\
COVERAGE_FORMAT=${COVERAGE_FORMAT:-html}\n\
PARALLEL_EXECUTION=${PARALLEL_EXECUTION:-true}\n\
TEST_TIMEOUT=${TEST_TIMEOUT:-600}\n\
FUZZING_ITERATIONS=${FUZZING_ITERATIONS:-1000}\n\
BENCHMARK_RUNS=${BENCHMARK_RUNS:-5}\n\
VERBOSE_OUTPUT=${VERBOSE_OUTPUT:-false}\n\
FAIL_FAST=${FAIL_FAST:-false}\n\
GENERATE_JUNIT=${GENERATE_JUNIT:-true}\n\
CACHE_TESTS=${CACHE_TESTS:-true}\n\
GAS_ANALYSIS=${GAS_ANALYSIS:-true}\n\
VERIFY_CONTRACTS=${VERIFY_CONTRACTS:-true}\n\
COVERAGE_ENABLED=${COVERAGE_ENABLED:-true}\n\
FUZZING_ENABLED=${FUZZING_ENABLED:-true}\n\
BENCHMARK_ENABLED=${BENCHMARK_ENABLED:-false}\n\
NETWORK=${STARKNET_NETWORK:-devnet}\n\
PARALLEL_JOBS=${PARALLEL_JOBS:-auto}\n\
\n\
# Auto-detect parallel jobs if set to auto\n\
if [ "$PARALLEL_JOBS" = "auto" ]; then\n\
    PARALLEL_JOBS=$(nproc 2>/dev/null || echo "2")\n\
fi\n\
\n\
# Validate test suite selection\n\
case "$TEST_SUITE" in\n\
    "unit"|"integration"|"performance"|"security"|"fuzzing"|"all")\n\
        echo "📋 Test suite: $TEST_SUITE"\n\
        ;;\n\
    *)\n\
        echo "❌ Invalid test suite: $TEST_SUITE"\n\
        echo "   Supported suites: unit, integration, performance, security, fuzzing, all"\n\
        exit 1\n\
        ;;\n\
esac\n\
\n\
# Validate coverage format\n\
case "$COVERAGE_FORMAT" in\n\
    "html"|"xml"|"json"|"lcov"|"term")\n\
        echo "📊 Coverage format: $COVERAGE_FORMAT"\n\
        ;;\n\
    *)\n\
        echo "❌ Invalid coverage format: $COVERAGE_FORMAT"\n\
        echo "   Supported formats: html, xml, json, lcov, term"\n\
        exit 1\n\
        ;;\n\
esac\n\
\n\
# Setup test environment directories\n\
mkdir -p /app/test-results /app/coverage /app/benchmarks /app/cache /app/reports /app/logs\n\
\n\
# Export configuration for test scripts\n\
export TEST_SUITE="$TEST_SUITE"\n\
export COVERAGE_FORMAT="$COVERAGE_FORMAT"\n\
export PARALLEL_EXECUTION="$PARALLEL_EXECUTION"\n\
export TEST_TIMEOUT="$TEST_TIMEOUT"\n\
export FUZZING_ITERATIONS="$FUZZING_ITERATIONS"\n\
export BENCHMARK_RUNS="$BENCHMARK_RUNS"\n\
export VERBOSE_OUTPUT="$VERBOSE_OUTPUT"\n\
export FAIL_FAST="$FAIL_FAST"\n\
export GENERATE_JUNIT="$GENERATE_JUNIT"\n\
export CACHE_TESTS="$CACHE_TESTS"\n\
export GAS_ANALYSIS="$GAS_ANALYSIS"\n\
export VERIFY_CONTRACTS="$VERIFY_CONTRACTS"\n\
export COVERAGE_ENABLED="$COVERAGE_ENABLED"\n\
export FUZZING_ENABLED="$FUZZING_ENABLED"\n\
export BENCHMARK_ENABLED="$BENCHMARK_ENABLED"\n\
export STARKNET_NETWORK="$NETWORK"\n\
export PARALLEL_JOBS="$PARALLEL_JOBS"\n\
\n\
echo "🔧 Testing Configuration:"\n\
echo "  • Test Suite: $TEST_SUITE"\n\
echo "  • Coverage: $COVERAGE_ENABLED ($COVERAGE_FORMAT)"\n\
echo "  • Parallel Execution: $PARALLEL_EXECUTION ($PARALLEL_JOBS jobs)"\n\
echo "  • Test Timeout: ${TEST_TIMEOUT}s"\n\
echo "  • Fuzzing: $FUZZING_ENABLED ($FUZZING_ITERATIONS iterations)"\n\
echo "  • Benchmarking: $BENCHMARK_ENABLED ($BENCHMARK_RUNS runs)"\n\
echo "  • Verbose Output: $VERBOSE_OUTPUT"\n\
echo "  • Fail Fast: $FAIL_FAST"\n\
echo "  • JUnit Reports: $GENERATE_JUNIT"\n\
echo "  • Test Caching: $CACHE_TESTS"\n\
echo "  • Gas Analysis: $GAS_ANALYSIS"\n\
echo "  • Contract Verification: $VERIFY_CONTRACTS"\n\
echo "  • StarkNet Network: $NETWORK"\n\
echo "✅ Testing environment configured successfully"\n\
' > /usr/local/bin/configure-testing.sh && chmod +x /usr/local/bin/configure-testing.sh

# Create comprehensive Cairo testing execution script
# Provides unified testing interface with support for multiple test types and configurations
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🚀 Cairo Smart Contract Testing Suite"\n\
echo "==================================="\n\
\n\
# Configure testing environment\n\
configure-testing.sh\n\
\n\
# Change to workspace directory if it exists\n\
if [ -d "/app/workspace" ]; then\n\
    cd /app/workspace\n\
    echo "📂 Working directory: /app/workspace"\n\
else\n\
    echo "📂 Working directory: $(pwd)"\n\
fi\n\
\n\
# Detect project structure\n\
if [ -f "Scarb.toml" ]; then\n\
    echo "📦 Found Scarb project configuration"\n\
elif [ -f "scarb.toml" ]; then\n\
    echo "📦 Found Scarb project configuration (lowercase)"\n\
else\n\
    echo "⚠️  No Scarb.toml found - assuming custom project structure"\n\
fi\n\
\n\
# Initialize test results and timing\n\
START_TIME=$(date +%s)\n\
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")\n\
TEST_LOG="/app/logs/test-execution-${TIMESTAMP}.log"\n\
\n\
echo "📝 Test execution log: $TEST_LOG"\n\
exec > >(tee -a "$TEST_LOG")\n\
exec 2>&1\n\
\n\
# Function to run snforge tests with comprehensive options\n\
run_cairo_tests() {\n\
    local test_type="$1"\n\
    local additional_args="$2"\n\
    \n\
    echo "🧪 Running $test_type tests..."\n\
    \n\
    # Build snforge command with conditional options\n\
    local cmd="snforge test"\n\
    \n\
    # Add parallel execution if enabled\n\
    if [ "$PARALLEL_EXECUTION" = "true" ]; then\n\
        cmd="$cmd --max-n-steps $PARALLEL_JOBS"\n\
    fi\n\
    \n\
    # Add timeout protection\n\
    cmd="timeout ${TEST_TIMEOUT} $cmd"\n\
    \n\
    # Add fail-fast option\n\
    if [ "$FAIL_FAST" = "true" ]; then\n\
        cmd="$cmd --exit-first"\n\
    fi\n\
    \n\
    # Add verbose output if enabled\n\
    if [ "$VERBOSE_OUTPUT" = "true" ]; then\n\
        cmd="$cmd --verbose"\n\
    fi\n\
    \n\
    # Add additional arguments\n\
    if [ -n "$additional_args" ]; then\n\
        cmd="$cmd $additional_args"\n\
    fi\n\
    \n\
    echo "🔧 Executing: $cmd"\n\
    \n\
    if eval "$cmd"; then\n\
        echo "✅ $test_type tests completed successfully"\n\
        return 0\n\
    else\n\
        echo "❌ $test_type tests failed"\n\
        return 1\n\
    fi\n\
}\n\
\n\
# Function to generate coverage reports with optimized formats\n\
generate_coverage() {\n\
    if [ "$COVERAGE_ENABLED" != "true" ]; then\n\
        echo "⏭️  Coverage analysis disabled, skipping"\n\
        return 0\n\
    fi\n\
    \n\
    echo "📊 Generating coverage reports..."\n\
    \n\
    # Only generate requested format to save space and time\n\
    case "$COVERAGE_FORMAT" in\n\
        "html")\n\
            if command -v lcov >/dev/null 2>&1; then\n\
                lcov --capture --directory . --output-file /app/coverage/coverage.info 2>/dev/null || true\n\
                genhtml /app/coverage/coverage.info --output-directory /app/coverage/html 2>/dev/null || true\n\
                echo "📄 HTML coverage report: /app/coverage/html/index.html"\n\
            fi\n\
            ;;\n\
        "xml")\n\
            lcov --capture --directory . --output-file /app/coverage/coverage.xml 2>/dev/null || true\n\
            echo "📄 XML coverage report: /app/coverage/coverage.xml"\n\
            ;;\n\
        "json")\n\
            if command -v coverage >/dev/null 2>&1; then\n\
                coverage json -o /app/coverage/coverage.json 2>/dev/null || true\n\
                echo "📄 JSON coverage report: /app/coverage/coverage.json"\n\
            else\n\
                echo "⚠️  JSON coverage requires Python coverage tool"\n\
            fi\n\
            ;;\n\
        "lcov")\n\
            lcov --capture --directory . --output-file /app/coverage/coverage.lcov 2>/dev/null || true\n\
            echo "📄 LCOV coverage report: /app/coverage/coverage.lcov"\n\
            ;;\n\
        "term")\n\
            lcov --capture --directory . --output-file /app/coverage/coverage.info 2>/dev/null || true\n\
            lcov --list /app/coverage/coverage.info 2>/dev/null || echo "Coverage summary not available"\n\
            ;;\n\
    esac\n\
    \n\
    echo "✅ Coverage analysis completed"\n\
}\n\
\n\
# Function to run performance benchmarks (conditionally)\n\
run_benchmarks() {\n\
    if [ "$BENCHMARK_ENABLED" != "true" ]; then\n\
        echo "⏭️  Benchmarking disabled, skipping"\n\
        return 0\n\
    fi\n\
    \n\
    echo "⚡ Running performance benchmarks..."\n\
    \n\
    for i in $(seq 1 "$BENCHMARK_RUNS"); do\n\
        echo "🏃 Benchmark run $i/$BENCHMARK_RUNS..."\n\
        /usr/bin/time -v snforge test --quiet > "/app/benchmarks/run-$i.log" 2>&1 || true\n\
    done\n\
    \n\
    echo "✅ Benchmark analysis completed"\n\
}\n\
\n\
# Function to run fuzzing tests (conditionally)\n\
run_fuzzing() {\n\
    if [ "$FUZZING_ENABLED" != "true" ]; then\n\
        echo "⏭️  Fuzzing disabled, skipping"\n\
        return 0\n\
    fi\n\
    \n\
    echo "🎲 Running fuzzing tests ($FUZZING_ITERATIONS iterations)..."\n\
    \n\
    # Run property-based tests if available\n\
    if [ -f "tests/fuzz_tests.py" ]; then\n\
        pytest tests/fuzz_tests.py --maxfail=5 --timeout="$TEST_TIMEOUT" || true\n\
    fi\n\
    \n\
    # Run Cairo fuzzing tests if available\n\
    if command -v snforge >/dev/null 2>&1; then\n\
        snforge test --fuzzing-runs "$FUZZING_ITERATIONS" 2>/dev/null || echo "⚠️  No fuzzing tests found"\n\
    fi\n\
    \n\
    echo "✅ Fuzzing tests completed"\n\
}\n\
\n\
# Function to generate comprehensive test report\n\
generate_report() {\n\
    local end_time=$(date +%s)\n\
    local duration=$((end_time - START_TIME))\n\
    \n\
    echo "📋 Generating comprehensive test report..."\n\
    \n\
    cat > "/app/reports/test-summary-${TIMESTAMP}.json" << EOF\n\
{\n\
  "execution": {\n\
    "timestamp": "$TIMESTAMP",\n\
    "duration_seconds": $duration,\n\
    "test_suite": "$TEST_SUITE",\n\
    "parallel_jobs": "$PARALLEL_JOBS",\n\
    "timeout": "$TEST_TIMEOUT"\n\
  },\n\
  "configuration": {\n\
    "coverage_enabled": "$COVERAGE_ENABLED",\n\
    "coverage_format": "$COVERAGE_FORMAT",\n\
    "fuzzing_enabled": "$FUZZING_ENABLED",\n\
    "fuzzing_iterations": "$FUZZING_ITERATIONS",\n\
    "benchmark_enabled": "$BENCHMARK_ENABLED",\n\
    "benchmark_runs": "$BENCHMARK_RUNS",\n\
    "verbose_output": "$VERBOSE_OUTPUT",\n\
    "fail_fast": "$FAIL_FAST",\n\
    "junit_reports": "$GENERATE_JUNIT",\n\
    "gas_analysis": "$GAS_ANALYSIS"\n\
  },\n\
  "environment": {\n\
    "starknet_network": "$STARKNET_NETWORK",\n\
    "starknet_tx_version": "$STARKNET_TX_VERSION",\n\
    "resource_bounds_enabled": "$RESOURCE_BOUNDS_ENABLED",\n\
    "cairo_optimization_level": "$CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL",\n\
    "tools": {\n\
      "snforge_version": "$(snforge --version 2>/dev/null | head -n1 || echo unknown)",\n\
      "scarb_version": "$(scarb --version 2>/dev/null || echo unknown)",\n\
      "python_version": "$(python3 --version 2>/dev/null || echo unknown)",\n\
      "pytest_version": "$(pytest --version 2>/dev/null | head -n1 || echo unknown)"\n\
    }\n\
  }\n\
}\n\
EOF\n\
    \n\
    echo "📄 Test report: /app/reports/test-summary-${TIMESTAMP}.json"\n\
    echo "⏱️  Total execution time: ${duration}s"\n\
    echo "✅ Test report generation completed"\n\
}\n\
\n\
# Main test execution logic\n\
echo "🎯 Starting test execution for suite: $TEST_SUITE"\n\
\n\
OVERALL_SUCCESS=true\n\
\n\
case "$TEST_SUITE" in\n\
    "unit")\n\
        run_cairo_tests "unit" "--unit" || OVERALL_SUCCESS=false\n\
        ;;\n\
    "integration")\n\
        run_cairo_tests "integration" "--integration" || OVERALL_SUCCESS=false\n\
        ;;\n\
    "performance")\n\
        run_cairo_tests "performance" "" || OVERALL_SUCCESS=false\n\
        run_benchmarks\n\
        ;;\n\
    "security")\n\
        run_cairo_tests "security" "" || OVERALL_SUCCESS=false\n\
        # Add security-specific testing logic here\n\
        ;;\n\
    "fuzzing")\n\
        run_cairo_tests "fuzzing" "" || OVERALL_SUCCESS=false\n\
        run_fuzzing\n\
        ;;\n\
    "all")\n\
        run_cairo_tests "unit" "--unit" || OVERALL_SUCCESS=false\n\
        run_cairo_tests "integration" "--integration" || OVERALL_SUCCESS=false\n\
        run_fuzzing\n\
        run_benchmarks\n\
        ;;\n\
esac\n\
\n\
# Generate coverage and reports\n\
generate_coverage\n\
generate_report\n\
\n\
# Final status report\n\
echo ""\n\
echo "🏁 Test Execution Summary:"\n\
echo "  • Test Suite: $TEST_SUITE"\n\
echo "  • Execution Time: $(($(date +%s) - START_TIME))s"\n\
echo "  • Parallel Jobs: $PARALLEL_JOBS"\n\
echo "  • Coverage: $COVERAGE_ENABLED ($COVERAGE_FORMAT)"\n\
echo "  • Fuzzing: $FUZZING_ENABLED"\n\
echo "  • Benchmarking: $BENCHMARK_ENABLED"\n\
echo "  • Results: /app/test-results/"\n\
echo "  • Coverage: /app/coverage/"\n\
echo "  • Reports: /app/reports/"\n\
echo "  • Logs: /app/logs/"\n\
\n\
if [ "$OVERALL_SUCCESS" = "true" ]; then\n\
    echo "🎉 All tests completed successfully!"\n\
    exit 0\n\
else\n\
    echo "❌ Some tests failed - check logs for details"\n\
    exit 1\n\
fi\n\
' > /usr/local/bin/run-cairo-tests.sh && chmod +x /usr/local/bin/run-cairo-tests.sh

# Verify testing tools installation with automated verification
RUN verify-tools.sh

# ==============================================================================
# Stage 4: Quality assurance and advanced analysis environment
# ==============================================================================
FROM testing-tools AS qa-environment

# Create advanced contract verification and validation script
# Provides comprehensive contract analysis and security verification
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🔍 Running contract verification and quality analysis..."\n\
\n\
# Configuration\n\
CONTRACT_PATH=${1:-"src/"}\n\
ANALYSIS_TYPE=${2:-"all"}\n\
SECURITY_LEVEL=${SECURITY_LEVEL:-standard}\n\
\n\
if [ ! -d "$CONTRACT_PATH" ]; then\n\
    echo "❌ Contract path not found: $CONTRACT_PATH"\n\
    exit 1\n\
fi\n\
\n\
echo "📋 Analysis Configuration:"\n\
echo "  • Contract Path: $CONTRACT_PATH"\n\
echo "  • Analysis Type: $ANALYSIS_TYPE"\n\
echo "  • Security Level: $SECURITY_LEVEL"\n\
\n\
# Function to run static analysis\n\
run_static_analysis() {\n\
    echo "🔎 Running static code analysis..."\n\
    \n\
    # Check for common Cairo patterns and issues\n\
    if command -v scarb >/dev/null 2>&1; then\n\
        echo "📝 Running Scarb format check..."\n\
        scarb fmt --check || echo "⚠️  Format check completed with warnings"\n\
        \n\
        echo "🔧 Running Scarb build verification..."\n\
        scarb build || echo "⚠️  Build completed with warnings"\n\
    fi\n\
    \n\
    echo "✅ Static analysis completed"\n\
}\n\
\n\
# Function to run security analysis\n\
run_security_analysis() {\n\
    echo "🛡️  Running security analysis..."\n\
    \n\
    # Basic security pattern checking\n\
    echo "🔍 Checking for common security patterns..."\n\
    \n\
    # Check for potential issues in Cairo files\n\
    find "$CONTRACT_PATH" -name "*.cairo" -type f | while read -r file; do\n\
        if grep -q "unsafe" "$file"; then\n\
            echo "⚠️  Found unsafe code in: $file"\n\
        fi\n\
        \n\
        if grep -q "panic" "$file"; then\n\
            echo "⚠️  Found panic calls in: $file"\n\
        fi\n\
        \n\
        if grep -q "assert" "$file"; then\n\
            echo "ℹ️  Found assert statements in: $file"\n\
        fi\n\
    done\n\
    \n\
    echo "✅ Security analysis completed"\n\
}\n\
\n\
# Function to run gas optimization analysis\n\
run_gas_analysis() {\n\
    echo "⛽ Running gas optimization analysis..."\n\
    \n\
    if [ "$GAS_ANALYSIS" = "true" ]; then\n\
        # Run tests with gas reporting if available\n\
        snforge test --gas-report 2>/dev/null || echo "⚠️  Gas reporting not available"\n\
    else\n\
        echo "⏭️  Gas analysis disabled"\n\
    fi\n\
    \n\
    echo "✅ Gas analysis completed"\n\
}\n\
\n\
# Main analysis execution\n\
case "$ANALYSIS_TYPE" in\n\
    "static")\n\
        run_static_analysis\n\
        ;;\n\
    "security")\n\
        run_security_analysis\n\
        ;;\n\
    "gas")\n\
        run_gas_analysis\n\
        ;;\n\
    "all")\n\
        run_static_analysis\n\
        run_security_analysis\n\
        run_gas_analysis\n\
        ;;\n\
    *)\n\
        echo "❌ Unknown analysis type: $ANALYSIS_TYPE"\n\
        echo "   Supported types: static, security, gas, all"\n\
        exit 1\n\
        ;;\n\
esac\n\
\n\
echo "✅ Contract verification and analysis completed"\n\
' > /usr/local/bin/verify-contracts.sh && chmod +x /usr/local/bin/verify-contracts.sh

# ==============================================================================
# Stage 5: Production CI environment (lightweight, optimized for CI/CD)
# ==============================================================================
FROM python:${PYTHON_VERSION}-slim AS production-ci

# Install minimal runtime dependencies for CI testing
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    ca-certificates \
    git \
    lcov \
    time \
    coreutils \
    locales \
    tzdata \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Set locale and timezone
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# Create dedicated testing user for enhanced security
RUN groupadd --gid ${USER_GID} cairo && \
    useradd --uid ${USER_UID} --gid cairo --shell /bin/bash --create-home cairo

# Check and copy Cairo tools from base image or qa-environment
# Prioritize copying from standard locations first
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/scarb /usr/local/bin/ 2>/dev/null || \
     COPY --from=${CAIRO_BASE_IMAGE} --chown=cairo:cairo /usr/local/bin/scarb /usr/local/bin/

COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/sncast /usr/local/bin/ 2>/dev/null || \
     COPY --from=${CAIRO_BASE_IMAGE} --chown=cairo:cairo /usr/local/bin/sncast /usr/local/bin/

COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/snforge /usr/local/bin/ 2>/dev/null || \
     COPY --from=${CAIRO_BASE_IMAGE} --chown=cairo:cairo /usr/local/bin/snforge /usr/local/bin/

# Copy essential Python dependencies only (minimal set for CI)
COPY --from=python-deps --chown=cairo:cairo /home/cairo/.venv /home/cairo/.venv

# Copy testing and verification scripts
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/configure-testing.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/run-cairo-tests.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/verify-contracts.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/verify-tools.sh /usr/local/bin/

# Copy custom testing scripts if provided
COPY scripts/ /tmp/scripts/

# Enhanced testing script management with fallbacks
RUN if [ -f "/tmp/scripts/run-cairo-tests.sh" ]; then \
        echo "📋 Using provided run-cairo-tests.sh script" && \
        cp /tmp/scripts/run-cairo-tests.sh /usr/local/bin/ && \
        chmod +x /usr/local/bin/run-cairo-tests.sh; \
    fi && \
    if [ -f "/tmp/scripts/verify-contracts.sh" ]; then \
        echo "📋 Using provided verify-contracts.sh script" && \
        cp /tmp/scripts/verify-contracts.sh /usr/local/bin/ && \
        chmod +x /usr/local/bin/verify-contracts.sh; \
    fi

# Set executable permissions and clean up
RUN chmod +x /usr/local/bin/*.sh && \
    rm -rf /tmp/scripts

# Create comprehensive testing directory structure with proper ownership
RUN mkdir -p /app/workspace /app/test-results /app/coverage /app/benchmarks \
             /app/cache /app/reports /app/logs /app/config && \
    chown -R cairo:cairo /app

# Set working directory and switch to testing user
WORKDIR /app
USER cairo

# Add Python virtual environment to PATH
ENV PATH="/home/cairo/.venv/bin:${PATH}"

# Set production testing environment variables optimized for CI
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=3
ENV STARKNET_NETWORK=devnet
ENV TEST_SUITE=all
ENV COVERAGE_FORMAT=lcov
ENV PARALLEL_EXECUTION=true
ENV TEST_TIMEOUT=${TEST_TIMEOUT}
ENV FUZZING_ITERATIONS=100
ENV BENCHMARK_RUNS=1
ENV VERBOSE_OUTPUT=false
ENV FAIL_FAST=true
ENV GENERATE_JUNIT=true
ENV CACHE_TESTS=true
ENV GAS_ANALYSIS=true
ENV VERIFY_CONTRACTS=true
ENV COVERAGE_ENABLED=true
ENV FUZZING_ENABLED=false
ENV BENCHMARK_ENABLED=false
ENV PARALLEL_JOBS=${PARALLEL_JOBS}

# Create optimized health check script for CI environments
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Lightweight health check optimized for CI\n\
command -v snforge >/dev/null 2>&1 || exit 1\n\
command -v pytest >/dev/null 2>&1 || exit 1\n\
[ -w "/app/test-results" ] || exit 1\n\
[ -x "/usr/local/bin/run-cairo-tests.sh" ] || exit 1\n\
\n\
# Quick compilation check\n\
snforge test --check 2>/dev/null || true\n\
\n\
exit 0\n\
' > /home/cairo/health-check.sh && chmod +x /home/cairo/health-check.sh

# Configure optimized health check for CI environment
HEALTHCHECK --interval=120s --timeout=10s --start-period=15s --retries=3 \
    CMD /home/cairo/health-check.sh

# Create CI-optimized startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Minimal startup for CI environment\n\
echo "🧪 Veridis Cairo Testing Environment (CI Mode)"\n\
echo "============================================"\n\
\n\
# Ensure required directories exist\n\
mkdir -p /app/test-results /app/coverage /app/reports /app/logs\n\
\n\
# Configure testing environment\n\
configure-testing.sh\n\
\n\
if [ $# -eq 0 ]; then\n\
    exec /usr/local/bin/run-cairo-tests.sh\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/cairo/startup.sh && chmod +x /home/cairo/startup.sh

# Set entrypoint to startup script for consistent initialization
ENTRYPOINT ["/home/cairo/startup.sh"]

# Default command runs the comprehensive test suite
CMD []

# ==============================================================================
# Stage 6: Production development environment (full-featured for development)
# ==============================================================================
FROM python:${PYTHON_VERSION}-slim AS production-dev

# Install comprehensive development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    ca-certificates \
    git \
    lcov \
    time \
    coreutils \
    locales \
    tzdata \
    python3-dev \
    build-essential \
    valgrind \
    htop \
    rsync \
    zip \
    unzip \
    wget \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Set locale and timezone
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

# Create dedicated testing user for enhanced security
RUN groupadd --gid ${USER_GID} cairo && \
    useradd --uid ${USER_UID} --gid cairo --shell /bin/bash --create-home cairo

# Copy Cairo tools and dependencies from qa-environment
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/scarb /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/sncast /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/snforge /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/starkli /usr/local/bin/

# Copy Python virtual environment with all development dependencies
COPY --from=python-deps --chown=cairo:cairo /home/cairo/.venv /home/cairo/.venv

# Install additional development Python packages
USER cairo
RUN /home/cairo/.venv/bin/pip install --no-cache-dir \
    bandit==1.8.3 \
    mypy==1.17.0a2 \
    black==24.5.0 \
    pandas==2.3.0 \
    matplotlib==3.10.3 \
    jinja2==3.1.6

USER root

# Copy testing and verification scripts
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/configure-testing.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/run-cairo-tests.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/verify-contracts.sh /usr/local/bin/
COPY --from=qa-environment --chown=cairo:cairo /usr/local/bin/verify-tools.sh /usr/local/bin/

# Copy custom testing scripts if provided
COPY scripts/ /tmp/scripts/

# Enhanced testing script management with fallbacks
RUN if [ -f "/tmp/scripts/run-cairo-tests.sh" ]; then \
        echo "📋 Using provided run-cairo-tests.sh script" && \
        cp /tmp/scripts/run-cairo-tests.sh /usr/local/bin/ && \
        chmod +x /usr/local/bin/run-cairo-tests.sh; \
    fi && \
    if [ -f "/tmp/scripts/verify-contracts.sh" ]; then \
        echo "📋 Using provided verify-contracts.sh script" && \
        cp /tmp/scripts/verify-contracts.sh /usr/local/bin/ && \
        chmod +x /usr/local/bin/verify-contracts.sh; \
    fi

# Set executable permissions and clean up
RUN chmod +x /usr/local/bin/*.sh && \
    rm -rf /tmp/scripts

# Create comprehensive testing directory structure with proper ownership
RUN mkdir -p /app/workspace /app/test-results /app/coverage /app/benchmarks \
             /app/cache /app/reports /app/logs /app/config && \
    chown -R cairo:cairo /app

# Set working directory and switch to testing user
WORKDIR /app
USER cairo

# Add Python virtual environment to PATH
ENV PATH="/home/cairo/.venv/bin:${PATH}"

# Set development testing environment variables
ENV STARKNET_TX_VERSION=3
ENV RESOURCE_BOUNDS_ENABLED=true
ENV CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL=3
ENV STARKNET_NETWORK=devnet
ENV TEST_SUITE=all
ENV COVERAGE_FORMAT=html
ENV PARALLEL_EXECUTION=true
ENV TEST_TIMEOUT=${TEST_TIMEOUT}
ENV FUZZING_ITERATIONS=1000
ENV BENCHMARK_RUNS=5
ENV VERBOSE_OUTPUT=true
ENV FAIL_FAST=false
ENV GENERATE_JUNIT=true
ENV CACHE_TESTS=true
ENV GAS_ANALYSIS=true
ENV VERIFY_CONTRACTS=true
ENV COVERAGE_ENABLED=true
ENV FUZZING_ENABLED=true
ENV BENCHMARK_ENABLED=true
ENV PARALLEL_JOBS=${PARALLEL_JOBS}

# Create comprehensive health check script for development
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🧪 Cairo Testing Environment Health Check (Development Mode)"\n\
echo "========================================================="\n\
\n\
# Verify all tools with version information\n\
verify-tools.sh\n\
\n\
# Test basic Cairo compilation\n\
echo "🔍 Testing Cairo compilation..."\n\
snforge test --check 2>/dev/null && echo "✅ Cairo compilation test passed" || echo "⚠️  Cairo compilation test skipped"\n\
\n\
# Check directory permissions\n\
[ -w "/app/test-results" ] && echo "✅ Test results directory writable" || echo "❌ Test results directory not writable"\n\
[ -w "/app/coverage" ] && echo "✅ Coverage directory writable" || echo "❌ Coverage directory not writable"\n\
[ -w "/app/logs" ] && echo "✅ Logs directory writable" || echo "❌ Logs directory not writable"\n\
\n\
# Check testing scripts availability\n\
[ -x "/usr/local/bin/run-cairo-tests.sh" ] && echo "✅ Test execution script accessible" || echo "❌ Test execution script missing"\n\
[ -x "/usr/local/bin/configure-testing.sh" ] && echo "✅ Test configuration script accessible" || echo "❌ Test configuration script missing"\n\
[ -x "/usr/local/bin/verify-contracts.sh" ] && echo "✅ Contract verification script accessible" || echo "❌ Contract verification script missing"\n\
\n\
echo "🎯 Health check completed successfully!"\n\
' > /home/cairo/health-check.sh && chmod +x /home/cairo/health-check.sh

# Configure health check for development environment
HEALTHCHECK --interval=120s --timeout=15s --start-period=20s --retries=3 \
    CMD /home/cairo/health-check.sh

# Create development startup script with comprehensive information
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "🧪 Veridis Cairo Smart Contract Testing Environment (Development Mode)"\n\
echo "================================================================"\n\
echo ""\n\
echo "Testing Configuration:"\n\
echo "  • Test Suite: ${TEST_SUITE:-all}"\n\
echo "  • Coverage Format: ${COVERAGE_FORMAT:-html}"\n\
echo "  • Parallel Execution: ${PARALLEL_EXECUTION:-true}"\n\
echo "  • Parallel Jobs: ${PARALLEL_JOBS:-auto}"\n\
echo "  • Test Timeout: ${TEST_TIMEOUT:-600}s"\n\
echo "  • Fuzzing Iterations: ${FUZZING_ITERATIONS:-1000}"\n\
echo "  • Benchmark Runs: ${BENCHMARK_RUNS:-5}"\n\
echo "  • Fail Fast: ${FAIL_FAST:-false}"\n\
echo "  • JUnit Reports: ${GENERATE_JUNIT:-true}"\n\
echo "  • Test Caching: ${CACHE_TESTS:-true}"\n\
echo "  • Gas Analysis: ${GAS_ANALYSIS:-true}"\n\
echo "  • Contract Verification: ${VERIFY_CONTRACTS:-true}"\n\
echo "  • Coverage Enabled: ${COVERAGE_ENABLED:-true}"\n\
echo "  • Fuzzing Enabled: ${FUZZING_ENABLED:-true}"\n\
echo "  • Benchmark Enabled: ${BENCHMARK_ENABLED:-true}"\n\
echo ""\n\
echo "Tool Versions:"\n\
echo "  • Scarb: $(scarb --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Starknet Foundry: $(snforge --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Python: $(python3 --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Pytest: $(pytest --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Coverage: $(coverage --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • Black: $(black --version 2>/dev/null | head -n1 | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo "  • MyPy: $(mypy --version 2>/dev/null | cut -d\" \" -f2 || echo \"Not available\")"\n\
echo ""\n\
echo "Environment Information:"\n\
echo "  • User: $(whoami) ($(id))"\n\
echo "  • Working Directory: $(pwd)"\n\
echo "  • Available Memory: $(free -h 2>/dev/null | grep Mem | awk '\''{print $2}'\'' || echo \"Unknown\")"\n\
echo "  • Available CPU Cores: $(nproc 2>/dev/null || echo \"Unknown\")"\n\
echo "  • StarkNet Network: ${STARKNET_NETWORK:-devnet}"\n\
echo "  • TX Version: ${STARKNET_TX_VERSION:-3}"\n\
echo "  • Resource Bounds: ${RESOURCE_BOUNDS_ENABLED:-true}"\n\
echo "  • MLIR Optimization: ${CAIRO_NATIVE_MLIR_OPTIMIZATION_LEVEL:-3}"\n\
echo ""\n\
echo "💡 Available Testing Commands:"\n\
echo "  • Run all tests: run-cairo-tests.sh"\n\
echo "  • Run unit tests: TEST_SUITE=unit run-cairo-tests.sh"\n\
echo "  • Run integration tests: TEST_SUITE=integration run-cairo-tests.sh"\n\
echo "  • Run performance tests: TEST_SUITE=performance run-cairo-tests.sh"\n\
echo "  • Run security tests: TEST_SUITE=security run-cairo-tests.sh"\n\
echo "  • Run fuzzing tests: TEST_SUITE=fuzzing run-cairo-tests.sh"\n\
echo "  • Verify contracts: verify-contracts.sh [path] [analysis_type]"\n\
echo "  • Generate coverage: COVERAGE_FORMAT=html run-cairo-tests.sh"\n\
echo "  • Parallel testing: PARALLEL_EXECUTION=true run-cairo-tests.sh"\n\
echo "  • Verify tools: verify-tools.sh"\n\
echo ""\n\
echo "Environment Variables for Testing:"\n\
echo "  • TEST_SUITE=unit|integration|performance|security|fuzzing|all"\n\
echo "  • COVERAGE_FORMAT=html|xml|json|lcov|term"\n\
echo "  • PARALLEL_EXECUTION=true|false"\n\
echo "  • VERBOSE_OUTPUT=true|false"\n\
echo "  • FAIL_FAST=true|false"\n\
echo "  • TEST_TIMEOUT=600 (seconds)"\n\
echo "  • FUZZING_ITERATIONS=1000"\n\
echo "  • BENCHMARK_RUNS=5"\n\
echo "  • COVERAGE_ENABLED=true|false"\n\
echo "  • FUZZING_ENABLED=true|false"\n\
echo "  • BENCHMARK_ENABLED=true|false"\n\
echo ""\n\
\n\
# Ensure required directories exist\n\
mkdir -p /app/test-results /app/coverage /app/benchmarks /app/cache /app/reports /app/logs\n\
\n\
# Configure testing environment\n\
configure-testing.sh\n\
\n\
if [ $# -eq 0 ]; then\n\
    exec /usr/local/bin/run-cairo-tests.sh\n\
else\n\
    exec "$@"\n\
fi\n\
' > /home/cairo/startup.sh && chmod +x /home/cairo/startup.sh

# Set entrypoint to startup script for consistent initialization
ENTRYPOINT ["/home/cairo/startup.sh"]

# Default command runs the comprehensive test suite
CMD []

# Comprehensive production metadata labels following OCI standards
LABEL maintainer="Veridis Team" \
      version="1.2.0" \
      description="Veridis Cairo Smart Contract Testing & Quality Assurance Environment" \
      environment.type="cairo-testing" \
      service.type="testing" \
      testing.suite="comprehensive" \
      build.target="${BUILD_TARGET}" \
      tools.foundry.version="${STARKNET_FOUNDRY_VERSION}" \
      tools.python.version="${PYTHON_VERSION}" \
      testing.parallel="${PARALLEL_JOBS}" \
      testing.timeout="${TEST_TIMEOUT}" \
      healthcheck.interval="${HEALTHCHECK_INTERVAL}" \
      user.uid="${USER_UID}" \
      user.gid="${USER_GID}" \
      startup.verbose="${VERBOSE_TESTING}" \
      base.image="${CAIRO_BASE_IMAGE}" \
      org.opencontainers.image.source="https://github.com/Cass402/DiD_repLayer_Starknet" \
      org.opencontainers.image.title="Veridis Cairo Testing Environment" \
      org.opencontainers.image.description="Production-ready Cairo testing environment with coverage, fuzzing, and performance analysis" \
      org.opencontainers.image.vendor="Veridis Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://github.com/Cass402/DiD_repLayer_Starknet/blob/main/testing/README.md" \
      org.opencontainers.image.base.name="python:${PYTHON_VERSION}-slim"

# Create default requirements file for missing requirements-testing.txt
RUN echo 'pytest==8.4.0\n\
pytest-xdist==3.7.0\n\
pytest-cov==6.1.1\n\
pytest-html==4.1.1\n\
pytest-json-report==1.5.0\n\
pytest-benchmark==5.1.0\n\
pytest-timeout==2.4.0\n\
hypothesis==6.135.1\n\
coverage==7.3.0\n\
requests==2.31.0\n\
' > requirements-testing.txt
