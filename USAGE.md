# Temperature Collector Usage Guide

## Installation

### For Production (Real Hardware)
```bash
# Install with hardware support
pip install .

# Or install dependencies manually
pip install w1thermsensor
```

### For Development/Testing (Mock Mode)
```bash
# Install in development mode
pip install -e .

# Or install with test dependencies
pip install -e ".[test]"
```

## Usage

### 1. Hardware Mode (Default)
```bash
# Run with real DS18B20 sensors
python -m therm.temperature_collector
```

### 2. Mock Mode (Testing)
```bash
# Force mock mode via environment variable
USE_MOCK_SENSORS=true python -m therm.temperature_collector

# Or use the test script
cd tests/
python test_temperature_collector.py --demo
```

### 3. Programmatic Usage
```python
from therm import TemperatureCollector

# Initialize (automatically detects hardware vs mock)
collector = TemperatureCollector()

# Read all temperatures
temperatures = collector.read_all_temperatures()

# Calculate efficiency
efficiency = collector.calculate_efficiency(temperatures)

# Continuous monitoring
collector.monitor_continuous(interval=30)
```

## Configuration

### Device Mapping (`devicenames.json`)
```json
{
    "T1": "28-32323232323232",  # Hot inlet
    "T2": "28-323232545454545", # Hot outlet
    "T3": "28-567890123456789", # Cold inlet
    "T4": "28-665656565656565"  # Cold outlet
}
```

## Environment Variables

- `USE_MOCK_SENSORS=true` - Force mock mode for testing
- `USE_MOCK_SENSORS=false` - Force hardware mode (override auto-detection)

## Testing

```bash
# Run unit tests
cd tests/
python -m pytest test_temperature_collector.py

# Run demo
python test_temperature_collector.py --demo

# Test with mock sensors
USE_MOCK_SENSORS=true python test_temperature_collector.py
```

## Features

### ✅ Conditional Imports
- Automatically uses mock sensors if `w1thermsensor` is not available
- Environment variable override for testing
- No hardware dependency for development

### ✅ Heat Exchanger Analysis
- Calculates efficiency: `(T4-T3) / (T1-T3) × 100`
- Performance interpretation (Excellent/Good/Fair/Poor)
- Temperature difference analysis

### ✅ Robust Error Handling
- Graceful sensor failures
- Missing sensor detection
- Invalid configuration handling

### ✅ Logging & Monitoring
- Continuous monitoring mode
- Automatic logging to file
- Real-time temperature display

## Troubleshooting

### Import Errors
```bash
# If you get "w1thermsensor not found"
pip install w1thermsensor

# Or use mock mode for testing
USE_MOCK_SENSORS=true python your_script.py
```

### Sensor Not Found
1. Check `devicenames.json` configuration
2. Verify sensor IDs with `ls /sys/bus/w1/devices/`
3. Run diagnostic script: `./scripts/w1_diagnostic.sh`
4. Use recovery script if needed: `./scripts/w1_bus_recovery.sh`

### Permission Errors
```bash
# Add user to gpio group (on Raspberry Pi)
sudo usermod -a -G gpio $USER

# Or run with sudo (not recommended for production)
sudo python -m therm.temperature_collector
```