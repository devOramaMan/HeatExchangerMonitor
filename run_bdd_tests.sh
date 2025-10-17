#!/bin/bash

# BDD Test Runner for HeatExchangerMonitor
echo "======================================================"
echo "Running BDD Tests for HeatExchangerMonitor"
echo "======================================================"

# Check if pytest-bdd is installed
python -c "import pytest_bdd" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "pytest-bdd not found. Installing test dependencies..."
    pip install -e ".[test]"
fi

# Force mock mode for testing
export USE_MOCK_SENSORS=true

echo "Running BDD scenarios..."
echo "------------------------------------------------------"

# Run the BDD tests with verbose output
pytest tests/test_temperature_collector.py -v --tb=short

if [ $? -eq 0 ]; then
    echo "------------------------------------------------------"
    echo "All BDD tests passed!"
    echo "======================================================"
else
    echo "------------------------------------------------------"
    echo "Some BDD tests failed. Check output above."
    echo "======================================================"
    exit 1
fi

echo ""
echo "Available test commands:"
echo "  pytest tests/                          # Run all tests"
echo "  pytest tests/test_temperature_collector.py  # Run BDD tests"
echo "  python tests/test_temperature_collector.py --demo  # Run demo"
echo "  USE_MOCK_SENSORS=true pytest tests/    # Force mock mode"