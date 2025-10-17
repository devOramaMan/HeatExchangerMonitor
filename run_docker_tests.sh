#!/bin/bash

# Docker Test Runner for HeatExchangerMonitor
echo "======================================================"
echo "HeatExchangerMonitor - Docker Test Runner"
echo "======================================================"

# Function to build Docker image
build_image() {
    echo "Building Docker test image..."
    docker build -f containers/pytest-bdd.Dockerfile -t heat-exchanger-test .
    return $?
}

# Function to run tests in Docker
run_tests() {
    echo "Running pytest-bdd tests in Docker..."
    docker run --rm \
        -e USE_MOCK_SENSORS=true \
        -e PYTHONPATH=/app \
        heat-exchanger-test \
        pytest tests/test_temperature_collector.py -v --tb=short
    return $?
}

# Function to run tests with coverage
run_tests_with_coverage() {
    echo "Running pytest-bdd tests with coverage in Docker..."
    docker run --rm \
        -e USE_MOCK_SENSORS=true \
        -e PYTHONPATH=/app \
        heat-exchanger-test \
        pytest tests/test_temperature_collector.py -v --cov=therm --cov-report=html --cov-report=term
    return $?
}

# Function to run interactive Docker shell
run_interactive() {
    echo "Starting interactive Docker shell..."
    docker run --rm -it \
        -e USE_MOCK_SENSORS=true \
        -e PYTHONPATH=/app \
        -v "$(pwd):/app" \
        heat-exchanger-test \
        /bin/bash
}

# Function to run Docker Compose
run_compose() {
    echo "Running Docker Compose tests..."
    docker-compose up pytest-bdd
    return $?
}

# Function to run Docker Compose with coverage
run_compose_coverage() {
    echo "Running Docker Compose tests with coverage..."
    docker-compose up pytest-bdd-coverage
    return $?
}

# Function to clean up Docker resources
cleanup() {
    echo "Cleaning up Docker resources..."
    docker-compose down --volumes --remove-orphans 2>/dev/null || true
    docker rmi heat-exchanger-test 2>/dev/null || true
    echo "Cleanup completed."
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build             Build Docker test image"
    echo "  test              Run tests in Docker"
    echo "  coverage          Run tests with coverage in Docker"
    echo "  interactive       Start interactive Docker shell"
    echo "  compose           Run tests with Docker Compose"
    echo "  compose-coverage  Run tests with coverage using Docker Compose"
    echo "  cleanup           Clean up Docker resources"
    echo "  all               Build and run tests"
    echo "  help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build && $0 test"
    echo "  $0 all"
    echo "  $0 coverage"
}

# Main logic
case "${1:-help}" in
    "build")
        build_image
        ;;
    "test")
        run_tests
        ;;
    "coverage")
        run_tests_with_coverage
        ;;
    "interactive"|"shell")
        run_interactive
        ;;
    "compose")
        run_compose
        ;;
    "compose-coverage")
        run_compose_coverage
        ;;
    "cleanup"|"clean")
        cleanup
        ;;
    "all")
        echo "Building and running all tests..."
        build_image && run_tests
        result=$?
        if [ $result -eq 0 ]; then
            echo ""
            echo "All Docker tests passed successfully!"
        else
            echo ""
            echo "Docker tests failed!"
        fi
        exit $result
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac