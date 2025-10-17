#!/usr/bin/env python3
"""
Mock W1ThermSensor for testing without hardware
"""

import random
from typing import Optional


class MockUnit:
    """Mock temperature units"""
    DEGREES_C = "celsius"
    DEGREES_F = "fahrenheit"
    KELVIN = "kelvin"


class MockSensor:
    """Mock sensor types"""
    DS18B20 = "DS18B20"


class MockW1ThermSensor:
    """
    Mock W1ThermSensor for testing without actual hardware
    Simulates realistic temperature readings for heat exchanger testing
    """
    
    def __init__(self, sensor_type=None, sensor_id=None):
        """
        Initialize mock sensor
        
        Args:
            sensor_type: Type of sensor (DS18B20)
            sensor_id: Sensor ID string
        """
        self.sensor_type = sensor_type or MockSensor.DS18B20
        self.sensor_id = sensor_id or "mock_sensor"
        
        # Simulate realistic temperatures for heat exchanger
        # Based on sensor name/ID, generate consistent temperature ranges
        self._base_temp = self._get_base_temperature()
        
    def _get_base_temperature(self) -> float:
        """Get base temperature based on sensor ID pattern"""
        sensor_str = str(self.sensor_id).lower()
        
        # Simulate different temperature ranges for different sensors
        if 'mock' in sensor_str:
            # Default mock temperatures
            return random.uniform(20.0, 25.0)
        elif sensor_str.endswith('32323232323232'):  # T1 - Hot inlet
            return 85.0
        elif sensor_str.endswith('323232545454545'):  # T2 - Hot outlet
            return 45.0
        elif sensor_str.endswith('567890123456789'):  # T3 - Cold inlet
            return 15.0
        elif sensor_str.endswith('665656565656565'):  # T4 - Cold outlet
            return 55.0
        else:
            # Random sensor
            return random.uniform(15.0, 85.0)
    
    def get_temperature(self, unit=None) -> float:
        """
        Get simulated temperature reading
        
        Args:
            unit: Temperature unit (MockUnit.DEGREES_C, etc.)
            
        Returns:
            Simulated temperature reading
        """
        unit = unit or MockUnit.DEGREES_C
        
        # Add small random variation to base temperature
        variation = random.uniform(-2.0, 2.0)
        temp_celsius = self._base_temp + variation
        
        # Convert units if needed
        if unit == MockUnit.DEGREES_F:
            return temp_celsius * 9/5 + 32
        elif unit == MockUnit.KELVIN:
            return temp_celsius + 273.15
        else:  # Default to Celsius
            return temp_celsius
            
    def get_id(self) -> str:
        """Get sensor ID"""
        return self.sensor_id
        
    def get_available_sensors(self):
        """Get list of available mock sensors"""
        return [
            MockW1ThermSensor(MockSensor.DS18B20, "32323232323232"),
            MockW1ThermSensor(MockSensor.DS18B20, "323232545454545"), 
            MockW1ThermSensor(MockSensor.DS18B20, "567890123456789"),
            MockW1ThermSensor(MockSensor.DS18B20, "665656565656565")
        ]


# Export mock classes with same names as real library
W1ThermSensor = MockW1ThermSensor
Unit = MockUnit
Sensor = MockSensor