#!/usr/bin/env python3
"""
Test file for TemperatureCollector with mock sensors using pytest-bdd
"""

import os
import sys
import pytest
from unittest.mock import patch, MagicMock
from pytest_bdd import scenario, given, when, then, parsers

# Add the parent directory to the path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Force mock mode for testing
os.environ['USE_MOCK_SENSORS'] = 'true'

from therm.temperature_collector import TemperatureCollector


# Test configuration
@pytest.fixture
def test_config():
    """Test configuration for sensors"""
    return {
        "T1": "28-32323232323232",
        "T2": "28-323232545454545", 
        "T3": "28-567890123456789",
        "T4": "28-665656565656565"
    }

@pytest.fixture
def temperature_collector(test_config):
    """Fixture to create a temperature collector with mock config"""
    with patch.object(TemperatureCollector, '_load_device_mapping', return_value=test_config):
        return TemperatureCollector()

# BDD Scenarios
@scenario('../features/temperature_collector.feature', 'Initialize temperature collector in mock mode')
def test_initialize_temperature_collector():
    """Test temperature collector initialization"""
    pass

@scenario('../features/temperature_collector.feature', 'Read temperature from a single sensor')
def test_read_single_temperature():
    """Test reading temperature from single sensor"""
    pass

@scenario('../features/temperature_collector.feature', 'Read temperatures from all sensors')
def test_read_all_temperatures():
    """Test reading temperatures from all sensors"""
    pass

@scenario('../features/temperature_collector.feature', 'Calculate heat exchanger efficiency with valid temperatures')
def test_calculate_efficiency():
    """Test efficiency calculation"""
    pass

@scenario('../features/temperature_collector.feature', 'Handle missing sensor data for efficiency calculation')
def test_missing_sensor_data():
    """Test handling missing sensor data"""
    pass

@scenario('../features/temperature_collector.feature', 'Handle zero temperature difference')
def test_zero_temperature_difference():
    """Test handling zero temperature difference"""
    pass

@scenario('../features/temperature_collector.feature', 'Handle invalid sensor reading')
def test_invalid_sensor_reading():
    """Test invalid sensor reading"""
    pass

# Step definitions
@given('I have a temperature collector with mock sensors')
def temperature_collector_context(temperature_collector):
    """Set up temperature collector context"""
    pytest.collector = temperature_collector

@given('the sensors are configured with test device IDs')
def sensors_configured():
    """Sensors are configured"""
    pass

@given('I have an initialized temperature collector')
def initialized_collector():
    """Temperature collector is initialized"""
    assert pytest.collector is not None

@given('I have temperature readings:')
def temperature_readings():
    """Set up temperature readings for efficiency calculation"""
    pytest.temperature_readings = {
        'T1': 85.0,  # Hot inlet
        'T2': 45.0,  # Hot outlet
        'T3': 15.0,  # Cold inlet
        'T4': 55.0   # Cold outlet
    }

@given('I have incomplete temperature readings:')
def incomplete_temperature_readings():
    """Set up incomplete temperature readings"""
    pytest.temperature_readings = {
        'T1': 85.0,
        'T2': 45.0
        # Missing T3, T4
    }

@given('I have temperature readings with zero difference:')
def zero_difference_readings():
    """Set up readings with zero temperature difference"""
    pytest.temperature_readings = {
        'T1': 50.0,
        'T2': 40.0,
        'T3': 50.0,  # Same as T1 - zero difference
        'T4': 60.0
    }

@given(parsers.parse('I have a mock DS18B20 sensor with ID "{sensor_id}"'))
def mock_sensor(sensor_id):
    """Create a mock sensor with specific ID"""
    from therm.mock_w1thermsensor import MockW1ThermSensor, MockSensor
    pytest.mock_sensor = MockW1ThermSensor(MockSensor.DS18B20, sensor_id)

@when('I initialize the temperature collector')
def initialize_collector():
    """Initialize the temperature collector"""
    pass  # Already done in fixture

@when(parsers.parse('I read temperature from sensor "{sensor_name}"'))
def read_temperature_from_sensor(sensor_name):
    """Read temperature from specific sensor"""
    pytest.temperature_reading = pytest.collector.read_temperature(sensor_name)

@when('I read temperatures from all sensors')
def read_all_temperatures():
    """Read temperatures from all sensors"""
    pytest.all_temperatures = pytest.collector.read_all_temperatures()

@when('I calculate the efficiency')
def calculate_efficiency():
    """Calculate efficiency from current readings"""
    pytest.efficiency = pytest.collector.calculate_efficiency(pytest.temperature_readings)

@when(parsers.parse('I try to read from invalid sensor "{sensor_name}"'))
def read_invalid_sensor(sensor_name):
    """Try to read from invalid sensor"""
    pytest.temperature_reading = pytest.collector.read_temperature(sensor_name)

@when('I get the temperature reading')
def get_mock_temperature_reading():
    """Get temperature reading from mock sensor"""
    pytest.mock_temperature = pytest.mock_sensor.get_temperature()

@then('it should be in mock mode')
def check_mock_mode():
    """Verify collector is in mock mode"""
    assert pytest.collector.using_mock == True

@then('it should have 4 sensors configured')
def check_sensor_count():
    """Verify sensor count"""
    assert len(pytest.collector.sensors) == 4

@then(parsers.parse('sensor "{sensor_name}" should be available'))
def check_sensor_available(sensor_name):
    """Verify specific sensor is available"""
    assert sensor_name in pytest.collector.sensors

@then('I should get a valid temperature reading')
def check_valid_temperature():
    """Verify temperature reading is valid"""
    assert pytest.temperature_reading is not None
    assert isinstance(pytest.temperature_reading, float)

@then('the temperature should be between 0 and 100 degrees')
def check_temperature_range_normal():
    """Check normal temperature range"""
    assert 0 < pytest.temperature_reading < 100

@then('I should get readings from 4 sensors')
def check_four_readings():
    """Verify we got 4 sensor readings"""
    assert len(pytest.all_temperatures) == 4

@then('all sensor readings should be valid floats')
def check_all_readings_valid():
    """Verify all readings are valid floats"""
    for temp in pytest.all_temperatures.values():
        assert isinstance(temp, float)

@then(parsers.parse('sensors "{sensors}" should all have readings'))
def check_sensors_present(sensors):
    """Verify all expected sensors have readings"""
    sensor_list = [s.strip().strip('"') for s in sensors.split(',')]
    for sensor in sensor_list:
        assert sensor in pytest.all_temperatures

@then(parsers.parse('the efficiency should be approximately {expected_efficiency:f} percent'))
def check_efficiency_value(expected_efficiency):
    """Check efficiency value"""
    assert pytest.efficiency is not None
    assert isinstance(pytest.efficiency, float)
    assert abs(pytest.efficiency - expected_efficiency) < 0.5  # Within 0.5%

@then('the efficiency should be None')
def check_efficiency_none():
    """Verify efficiency is None"""
    assert pytest.efficiency is None

@then('the reading should be None')
def check_reading_none():
    """Verify reading is None"""
    assert pytest.temperature_reading is None

@then('the temperature should be a valid float')
def check_mock_temperature_valid():
    """Verify mock temperature is valid float"""
    assert isinstance(pytest.mock_temperature, float)

@then('the temperature should be between -50 and 150 degrees')
def check_temperature_range_extended():
    """Check extended temperature range"""
    assert -50 < pytest.mock_temperature < 150

@then('the temperature should be between 80 and 90 degrees')
def check_hot_temperature_range():
    """Check hot sensor temperature range"""
    assert 80 < pytest.mock_temperature < 90

@then('the temperature should be between 10 and 20 degrees')
def check_cold_temperature_range():
    """Check cold sensor temperature range"""
    assert 10 < pytest.mock_temperature < 20


# Additional BDD scenarios for mock sensor testing
@scenario('../features/temperature_collector.feature', 'Test mock sensor functionality')
def test_mock_sensor_functionality():
    """Test mock sensor functionality"""
    pass

@scenario('../features/temperature_collector.feature', 'Test temperature consistency for specific sensors')
def test_temperature_consistency_hot():
    """Test temperature consistency for hot sensors"""
    pass

@scenario('../features/temperature_collector.feature', 'Test cold sensor temperature consistency')
def test_temperature_consistency_cold():
    """Test temperature consistency for cold sensors"""
    pass

