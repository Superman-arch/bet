#!/bin/bash

# Quick test script for rapid development testing
# Run specific tests without full setup

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
TEST_CLASS=""
TEST_METHOD=""
SKIP_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--class)
            TEST_CLASS="$2"
            shift 2
            ;;
        -m|--method)
            TEST_METHOD="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-c TestClass] [-m testMethod] [-s]"
            exit 1
            ;;
    esac
done

# Build test target
if [ "$SKIP_BUILD" = false ]; then
    echo "Building test target..."
    xcodebuild build-for-testing \
        -scheme BetApp \
        -destination "platform=iOS Simulator,name=iPhone 14 Pro" \
        -quiet
fi

# Construct test filter
TEST_FILTER=""
if [ -n "$TEST_CLASS" ]; then
    TEST_FILTER="-only-testing:BetAppTests/$TEST_CLASS"
    if [ -n "$TEST_METHOD" ]; then
        TEST_FILTER="$TEST_FILTER/$TEST_METHOD"
    fi
fi

# Run tests
echo "Running tests..."
if xcodebuild test-without-building \
    -scheme BetApp \
    -destination "platform=iOS Simulator,name=iPhone 14 Pro" \
    $TEST_FILTER \
    -quiet; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi