#!/usr/bin/env python3
"""
Temperature Collector for Heat Exchanger Monitor
Collects temperature readings from 4 DS18B20 sensors and calculates efficiency
"""

import json
import time
import os
from datetime import datetime
from typing import Dict, Optional
from .mock_w1thermsensor import W1ThermSensor as SimulatedW1ThermSensor
from .mock_w1thermsensor import Sensor as MockSensor
import logging

log = logging.getLogger(__name__)

# Check environment variable first for mock override
USE_MOCK_OVERRIDE = os.environ.get('USE_MOCK_SENSORS', '').lower() in ('true', '1', 'yes')

# Conditional import for w1thermsensor with mock fallback
if USE_MOCK_OVERRIDE:
    print("Using mock sensors due to USE_MOCK_SENSORS environment variable")
    from .mock_w1thermsensor import W1ThermSensor, Unit, Sensor
    USING_MOCK = True
else:
    try:
        from w1thermsensor import W1ThermSensor, Unit, Sensor
        USING_MOCK = False
        print("Using real W1ThermSensor hardware interface")
    except ImportError:
        print("W1ThermSensor not available, using mock interface for testing")
        from .mock_w1thermsensor import W1ThermSensor, Unit, Sensor
        USING_MOCK = True




class TemperatureCollector:
    def __init__(self, config_file: str = "devicenames.json"):
        """
        Initialize temperature collector
        
        Args:
            config_file: Path to JSON file with sensor mappings
        """
        self.config_file = config_file
        self.device_mapping = self._load_device_mapping()
        self.sensors = {}
        self.using_mock = USING_MOCK or USE_MOCK_OVERRIDE
        self._initialize_sensors()
        
    def _load_device_mapping(self) -> Dict[str, str]:
        """Load sensor device mappings from JSON file"""
        try:
            config_path = os.path.join(os.path.dirname(__file__), self.config_file)
            with open(config_path, 'r') as f:
                mapping = json.load(f)
            log.info(f"Loaded device mapping: {mapping}")
            return mapping
        except FileNotFoundError:
            log.error(f"Config file {self.config_file} not found!")
            raise
        except json.JSONDecodeError as e:
            log.error(f"Invalid JSON in {self.config_file}: {e}")
            raise
            
    def _initialize_sensors(self):
        """Initialize W1ThermSensor objects for each configured device"""
        for name, device_id in self.device_mapping.items():
            try:
                # Extract the sensor ID from the device path (remove "28-" prefix)
                sensor_id = device_id.replace("28-", "")
                if 'simulated' in sensor_id.lower():
                    sensor = SimulatedW1ThermSensor(MockSensor.DS18B20, sensor_id)
                else:
                    sensor = W1ThermSensor(Sensor.DS18B20, sensor_id)
                self.sensors[name] = sensor
                log.info(f"Initialized sensor {name} (ID: {device_id})")
            except Exception as e:
                log.error(f"Failed to initialize sensor {name} (ID: {device_id}): {e}")

    def read_temperature(self, sensor_name: str, unit = None) -> Optional[float]:
        """
        Read temperature from a specific sensor
        
        Args:
            sensor_name: Name of the sensor (T1, T2, T3, T4)
            unit: Temperature unit (default: Celsius)
            
        Returns:
            Temperature reading or None if failed
        """
        if sensor_name not in self.sensors:
            log.warning(f"Sensor {sensor_name} not found!")
            return None
            
        # Set default unit if not provided
        if unit is None:
            unit = Unit.DEGREES_C
            
        try:
            temperature = self.sensors[sensor_name].get_temperature(unit)
            log.info(f"{sensor_name}: {temperature:.2f}°C")
            return temperature
        except Exception as e:
            log.error(f"Error reading {sensor_name}: {e}")
            return None
            
    def read_all_temperatures(self) -> Dict[str, float]:
        """
        Read temperatures from all configured sensors
        
        Returns:
            Dictionary with sensor names as keys and temperatures as values
        """
        temperatures = {}
        log.info(f"Reading temperatures at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        log.info("-" * 50)

        for sensor_name in self.device_mapping.keys():
            temp = self.read_temperature(sensor_name)
            if temp is not None:
                temperatures[sensor_name] = temp
                
        return temperatures
        
    def calculate_efficiency(self, temperatures: Dict[str, float]) -> Optional[float]:
        """
        Calculate heat exchanger efficiency
        Assumes: T1=Hot_in, T2=Hot_out, T3=Cold_in, T4=Cold_out
        
        Efficiency = (T4-T3) / (T1-T3) * 100
        
        Args:
            temperatures: Dictionary with temperature readings
            
        Returns:
            Efficiency percentage or None if calculation fails
        """
        required_sensors = ['T1', 'T2', 'T3', 'T4']
        
        # Check if all required sensors have readings
        for sensor in required_sensors:
            if sensor not in temperatures:
                log.warning(f"Missing temperature reading for {sensor}")
                return None
                
        try:
            T1 = temperatures['T1']  # Hot inlet
            T2 = temperatures['T2']  # Hot outlet  
            T3 = temperatures['T3']  # Cold inlet
            T4 = temperatures['T4']  # Cold outlet

            log.info(f"\nHeat Exchanger Analysis:")
            log.info(f"   Hot side:  {T1:.2f}°C -> {T2:.2f}°C (dT = {T1-T2:.2f}°C)")
            log.info(f"   Cold side: {T3:.2f}°C -> {T4:.2f}°C (dT = {T4-T3:.2f}°C)")

            # Calculate effectiveness (efficiency)
            if T1 - T3 == 0:
                log.warning("Cannot calculate efficiency: No temperature difference between hot and cold inlet")
                return None
                
            efficiency = (T4 - T3) / (T1 - T3) * 100

            log.info(f"Heat Exchanger Efficiency: {efficiency:.1f}%")
            
                
            return efficiency
            
        except Exception as e:
            log.error(f"Error calculating efficiency: {e}")
            return None
            
    def monitor_continuous(self, interval: int = 30, callback=None):
        """
        Continuously monitor temperatures and efficiency
        
        Args:
            interval: Reading interval in seconds
        """
        log.info(f"Starting continuous monitoring (interval: {interval}s)")
        log.info("Press Ctrl+C to stop")
        
        try:
            while True:
                temperatures = self.read_all_temperatures()
                
                if temperatures:
                    efficiency = self.calculate_efficiency(temperatures)
                    temperatures['Efficiency'] = efficiency
                    
                    # Log to file (optional)
                    self._log_reading(temperatures, efficiency)
                
                if callback:
                    callback(temperatures)

                log.info(f"Next reading in {interval} seconds...")
                time.sleep(interval)
                
        except KeyboardInterrupt:
            log.info("Monitoring stopped by user")

    def _log_reading(self, temperatures: Dict[str, float], efficiency: Optional[float]):
        """Log reading to file (optional feature)"""
        try:
            log_file = os.path.join(os.path.dirname(__file__), "temperature_log.txt")
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            with open(log_file, 'a') as f:
                f.write(f"{timestamp}")
                for name, temp in temperatures.items():
                    f.write(f",{name}:{temp:.2f}")
                if efficiency is not None:
                    f.write(f",Efficiency:{efficiency:.1f}%")
                f.write("\n")
                
        except Exception as e:
            log.warning(f"Could not write to log file: {e}")


def main():
    """Main function"""
    # set logger format 
    logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
    # output to console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    logging.getLogger().addHandler(console_handler)

    try:
        # Initialize collector
        collector = TemperatureCollector()
        
        # Show mode information
        mode = "MOCK MODE" if collector.using_mock else "HARDWARE MODE"
        print(f"\n=== Temperature Collector {mode} ===")
        
        if collector.using_mock:
            print("Tip: Set environment variable USE_MOCK_SENSORS=false to use real hardware")
        
        # Single reading
        log.info("\n=== Single Temperature Reading ===")
        temperatures = collector.read_all_temperatures()
        
        if temperatures:
            efficiency = collector.calculate_efficiency(temperatures)
            log.info(f"temperature reading: {temperatures}, efficiency: {efficiency:.1f}%")
        
        # Ask if user wants continuous monitoring
        log.info("\n" + "="*50)
        response = input("Start continuous monitoring? (y/N): ").lower()
        
        if response in ['y', 'yes']:
            try:
                interval = int(input("Enter reading interval in seconds (default 30): ") or "30")
                collector.monitor_continuous(interval)
            except ValueError:
                log.warning("Invalid interval, using default (30s)")
                collector.monitor_continuous(30)
        else:
            log.info("Single reading complete.")

    except Exception as e:
        log.error(f"Error: {e}")
        return 1
        
    return 0


if __name__ == "__main__":
    exit(main())