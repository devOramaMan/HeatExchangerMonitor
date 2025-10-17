# HeatExchangerMonitor

# depends
```  sh
sudo apt install python3-venv python3-full python3-pip
# Possibly requre to be done in environment (ref python env)
pip install w1thermsensor
pip install pytest
pip install pytest-bdd
```

## python env
``` sh
python3 -m venv ~/myenv
#enter
source ~/myenv/bin/activate
#exit
deactivate
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

