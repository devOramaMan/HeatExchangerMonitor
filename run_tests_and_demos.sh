#!/bin/bash

# Test and Demo Runner for HeatExchangerMonitor
echo "======================================================"
echo "HeatExchangerMonitor - Test & Demo Runner"
echo "======================================================"

# Function to run BDD tests
run_bdd_tests() {
    echo "Running BDD Tests..."
    echo "------------------------------------------------------"
    pytest tests/test_temperature_collector.py -v --tb=short
    return $?
}

# Function to run demo
run_demo() {
    echo "Running Interactive Demo..."
    echo "------------------------------------------------------"
    python demo.py
    return $?
}

# Function to run temperature collector main program
run_main_program() {
    echo "Running Temperature Collector Main Program..."
    echo "------------------------------------------------------"
    echo "Note: This will run the main temperature collector."
    echo "Press Ctrl+C to stop continuous monitoring."
    echo ""
    python demo.py --main
    return $?
}

# Function to show help
show_help() {
    echo "Available commands:"
    echo ""
    echo "  ./run_tests_and_demos.sh test       Run BDD tests"
    echo "  ./run_tests_and_demos.sh demo       Run demonstration"
    echo "  ./run_tests_and_demos.sh main       Run main temperature collector"
    echo "  ./run_tests_and_demos.sh all        Run tests and demo"
    echo "  ./run_tests_and_demos.sh help       Show this help"
    echo ""
    echo "Direct pytest commands:"
    echo "  pytest tests/                       Run all tests"
    echo "  pytest tests/test_temperature_collector.py -v  Run BDD tests verbose"
    echo ""
    echo "Direct demo commands:"
    echo "  python demo.py                      Full demo"
    echo "  python demo.py --mock-only          Mock sensor demo only"
    echo "  python demo.py --main               Main temperature collector program"
    echo ""
    echo "Environment variables:"
    echo "  USE_MOCK_SENSORS=true              Force mock mode"
    echo "  USE_MOCK_SENSORS=false             Force hardware mode"
}

# Main logic
case "${1:-help}" in
    "test"|"tests")
        run_bdd_tests
        exit $?
        ;;
    "demo")
        run_demo
        exit $?
        ;;
    "main"|"run")
        run_main_program
        exit $?
        ;;
    "all")
        echo "Running all tests and demos..."
        echo ""
        
        run_bdd_tests
        test_result=$?
        
        if [ $test_result -eq 0 ]; then
            echo ""
            echo "Tests passed! Running demo..."
            echo ""
            run_demo
            demo_result=$?
            
            if [ $demo_result -eq 0 ]; then
                echo ""
                echo "======================================================"
                echo "All tests and demos completed successfully!"
                echo "======================================================"
            else
                echo ""
                echo "Demo failed!"
                exit 1
            fi
        else
            echo ""
            echo "Tests failed! Skipping demo."
            exit 1
        fi
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