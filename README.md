# HeatExchangerMonitor

# depends
```  sh
sudo apt install python3-venv python3-full python3-pip
# May require installation in virtual environment on target(see python virtual environment)
pip install w1thermsensor pytest pytest-bdd azure-messaging-webpubsubservice websocketspi
```

## python virtual environment

``` sh
python3 -m venv ~/myenv
#enter
source ~/myenv/bin/activate
#exit
deactivate
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
```

Tests run in Docker image for CI/CD
```bash
# To print the command options
./run_docker_tests.sh
# Do all Build and run test
./run_docker_tests.sh all
# Run tests in Docker
./run_docker_tests.sh  test
```


## Troubleshooting

### Diagnostic Scripts

The `scripts/` directory contains some scripts to troubleshooting 1-Wire sensor issues:

- **`w1_diagnostic.sh`** - checks
  - 1-Wire kernel modules (w1-gpio, w1-therm) 
  - Bus interface and masters
  - Connected devices and their status
  - GPIO configuration and permissions
  - Provides specific recommendations for fixing issues

- **`w1_bus_recovery.sh`** - Recovery tool for stuck or problematic 1-Wire buses:
  - Complete 1-Wire system reset (removes and reloads modules)
  - Clears phantom/stuck devices
  - Reinitializes bus masters
  - Triggers device discovery
  - Interactive prompts for safe operation

Run these scripts when experiencing sensor connection problems or to verify your 1-Wire setup.

### Common Issues

1. **GPIO Permission/Access Issues** (`Failed to get GPIO line handle`):
   ```bash
   # Add user to gpio group
   sudo usermod -a -G gpio $USER
   # Logout and login again
   
   # Check GPIO device permissions
   ls -la /dev/gpiochip*
   ```

2. **System Diagnostics and GPIO Analysis**:
   ```bash
   # Run 1-Wire and GPIO diagnostics
   ./scripts/w1_diagnostic.sh
   
   # This script will check:
   # - Kernel modules (w1-gpio, w1-therm)
   # - Device tree overlays
   # - GPIO pin configuration and conflicts
   # - 1-Wire bus status and devices
   ```

3. **W1 Bus Recovery** (if needed):
   ```bash
   # Run bus recovery script
   ./scripts/w1_bus_recovery.sh
   
   # This script handles:
   # - Module reloading
   # - GPIO reset procedures
   # - Bus reinitialization
   sudo nano /boot/config.txt
   # Comment out: #dtoverlay=w1-gpio
   sudo reboot
   ```

4. **Hardware Verification**:
   - **Pull-up resistor**: Must have 4.7kΩ between DQ and 3.3V
   - **Sensor orientation**: Flat side facing you: GND, DQ, VDD
   - **Connections**: Verify all wiring is secure

5. **No devices found**:
   - Check wiring connections
   - Verify pull-up resistor (4.7kΩ)
   - Ensure 1-Wire is enabled in raspi-config
   - Check GPIO permissions

6. **CRC errors**:
   - Check for electromagnetic interference
   - Verify cable lengths (keep short)
   - Ensure good connections

4. **Linux W1 device not found**:
   ```bash
   # Check if 1-Wire is enabled
   ls /sys/bus/w1/devices/
   
   # Reload modules if needed
   sudo modprobe w1-gpio
   sudo modprobe w1-therm
   # this is also done using the scripts
   ./scripts/w1_diagnostic.sh
   ./scripts/w1_bus_recovery.sh
   ```

