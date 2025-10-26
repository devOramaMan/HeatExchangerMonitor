# HeatExchangerMonitor

# depends
```  sh
sudo apt install python3-venv python3-full python3-pip
# May require installation in virtual environment on target(see python virtual environment)
pip install w1thermsensor pytest pytest-bdd azure-messaging-webpubsubservice websockets
```

## python virtual environment

``` sh
python3 -m venv ~/myenv
#enter
source ~/myenv/bin/activate
#exit
deactivate
```

### 3. Programmatic Usage Temperature Collector

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

# Publish temperature Collector to Web / DB


```bash
   #Get the connection string
   az webpubsub key show \
   --name HeatExchangerService \
   --resource-group HeatExchangerRG \
   --query primaryConnectionString \
   -o tsv
```
Create secrets file  secrets.json
```bash
   "PG_DB_HOST": ""
    "PG_DB_NAME": ""
    "PG_DB_PASSWORD": "" 
    "PG_DB_PORT": ""
    "PG_DB_USER": ""
    "AZURE_WEBPUBSUB_CONNECTION_STRING": "connection string"
```


## Setting up Systemd Service for Continuous Monitoring

To run the temperature collector as a system service that starts automatically on boot, you'll need to create a systemd service file that properly handles the Python virtual environment.

### 1. Create a Runner executable

First, create a runner.py exe (bundle dependencies)

```bash
# Create the runner 
pyinstaller --onefile --add-data "./therm/devicenames.json:." --add-data "secrets.json:." ./runner.py
cp ./secrets.json ./dist
cp therm/devicenames.json ./dist
```

### 2. Create Installation Directory and Setup

```bash
# Create service directory
sudo mkdir -p /opt/heat-exchanger

# Create dedicated service user
sudo useradd --system --shell /bin/false --home /opt/heat-exchanger --create-home heat-exchanger

# Copy application files
sudo cp dist/* /opt/heat-exchanger/

# Set proper ownership and permissions
sudo chown -R heat-exchanger:heat-exchanger /opt/heat-exchanger
sudo chmod +x /opt/heat-exchanger/runner

# Add heat-exchanger user to gpio group (for hardware access)
sudo usermod -a -G gpio heat-exchanger
```

### 4. Create Systemd Service File

```bash
sudo vi /etc/systemd/system/heat-exchanger.service
```

```ini
[Unit]
Description=Heat Exchanger Temperature Monitor
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=heat-exchanger
Group=heat-exchanger
WorkingDirectory=/opt/heat-exchanger
ExecStart=/opt/heat-exchanger/runner
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=heat-exchanger

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/log
ReadOnlyPaths=/opt/heat-exchanger

[Install]
WantedBy=multi-user.target
```

### 5. Enable and Start the Service

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable heat-exchanger.service

# Start the service
sudo systemctl start heat-exchanger.service

# Check service status
sudo systemctl status heat-exchanger.service
```

### 6. Service Management Commands

```bash
# View service logs
sudo journalctl -u heat-exchanger.service -f

# Stop the service
sudo systemctl stop heat-exchanger.service

# Restart the service
sudo systemctl restart heat-exchanger.service

# Disable service from starting on boot
sudo systemctl disable heat-exchanger.service

# View recent logs
sudo journalctl -u heat-exchanger.service --since "1 hour ago"
```

### 7. Log File Location

The service logs to both:
- **systemd journal**: `sudo journalctl -u heat-exchanger.service`
- **Log file**: `/var/log/heat-exchanger.log`

```bash
# Create log file with proper permissions
sudo touch /var/log/heat-exchanger.log
sudo chown $USER:$USER /var/log/heat-exchanger.log

# View log file
tail -f /var/log/heat-exchanger.log
```

### 8. Troubleshooting Service Issues

**Error: "Failed at step USER spawning... No such process"**
```bash
# Check if heat-exchanger user exists
id heat-exchanger

# If user doesn't exist, create it:
sudo useradd --system --shell /bin/false --home /opt/heat-exchanger heat-exchanger

# Fix ownership and permissions
sudo chown -R heat-exchanger:heat-exchanger /opt/heat-exchanger
sudo chmod +x /opt/heat-exchanger/runner

# Reload and restart service
sudo systemctl daemon-reload
sudo systemctl restart heat-exchanger.service
```

**Check executable permissions:**
```bash
# Verify executable is accessible
sudo -u heat-exchanger /opt/heat-exchanger/runner --help

# Check file permissions
ls -la /opt/heat-exchanger/runner
# Should show: -rwxr-xr-x ... heat-exchanger heat-exchanger ... runner
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

