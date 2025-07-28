#!/bin/bash

# Bet App Test Runner Script
# This script sets up and runs all tests for the Bet app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCHEME="BetApp"
DESTINATION="platform=iOS Simulator,name=iPhone 14 Pro"
PROJECT="BetApp.xcodeproj"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed"
        exit 1
    fi
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check for Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_warning "Supabase CLI not found. Installing..."
        brew install supabase/tap/supabase
    fi
    
    log_info "All dependencies satisfied ✓"
}

start_services() {
    log_info "Starting local services..."
    
    # Start Docker services
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to start..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Exit"; then
        log_error "Some services failed to start"
        docker-compose logs
        exit 1
    fi
    
    log_info "Services started successfully ✓"
}

setup_database() {
    log_info "Setting up test database..."
    
    # Apply migrations
    supabase db push --local
    
    # Seed test data
    docker exec -i bet-postgres psql -U postgres postgres < supabase/seed.sql
    
    log_info "Database setup complete ✓"
}

run_unit_tests() {
    log_info "Running unit tests..."
    
    xcodebuild test \
        -scheme "$SCHEME" \
        -project "$PROJECT" \
        -destination "$DESTINATION" \
        -only-testing:BetAppTests/Unit \
        -quiet || {
            log_error "Unit tests failed"
            return 1
        }
    
    log_info "Unit tests passed ✓"
}

run_integration_tests() {
    log_info "Running integration tests..."
    
    xcodebuild test \
        -scheme "$SCHEME" \
        -project "$PROJECT" \
        -destination "$DESTINATION" \
        -only-testing:BetAppTests/Integration \
        -quiet || {
            log_error "Integration tests failed"
            return 1
        }
    
    log_info "Integration tests passed ✓"
}

run_ui_tests() {
    log_info "Running UI tests..."
    
    # Disable hardware keyboard for UI tests
    defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
    
    xcodebuild test \
        -scheme "$SCHEME" \
        -project "$PROJECT" \
        -destination "$DESTINATION" \
        -only-testing:BetAppTests/UI \
        -quiet || {
            log_error "UI tests failed"
            return 1
        }
    
    log_info "UI tests passed ✓"
}

generate_coverage() {
    log_info "Generating test coverage report..."
    
    xcodebuild test \
        -scheme "$SCHEME" \
        -project "$PROJECT" \
        -destination "$DESTINATION" \
        -enableCodeCoverage YES \
        -quiet
    
    # Find the latest .xcresult file
    RESULT_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | head -n 1)
    
    if [ -n "$RESULT_PATH" ]; then
        log_info "Coverage report generated at: $RESULT_PATH"
    fi
}

cleanup() {
    log_info "Cleaning up..."
    
    # Stop services
    docker-compose down
    
    # Reset simulator
    xcrun simctl shutdown all
    
    log_info "Cleanup complete ✓"
}

# Main execution
main() {
    log_info "Starting Bet App test suite..."
    
    # Parse arguments
    case "$1" in
        "unit")
            check_dependencies
            run_unit_tests
            ;;
        "integration")
            check_dependencies
            start_services
            setup_database
            run_integration_tests
            cleanup
            ;;
        "ui")
            check_dependencies
            start_services
            setup_database
            run_ui_tests
            cleanup
            ;;
        "all")
            check_dependencies
            start_services
            setup_database
            run_unit_tests
            run_integration_tests
            run_ui_tests
            generate_coverage
            cleanup
            ;;
        "coverage")
            check_dependencies
            generate_coverage
            ;;
        *)
            echo "Usage: $0 {unit|integration|ui|all|coverage}"
            exit 1
            ;;
    esac
    
    log_info "Test run complete! 🎉"
}

# Handle interrupts
trap cleanup EXIT INT TERM

# Run main function with all arguments
main "$@"