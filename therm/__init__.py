#!/usr/bin/env python3
"""
HeatExchangerMonitor - Temperature monitoring package for DS18B20 sensors

This package provides temperature monitoring functionality for heat exchangers
using DS18B20 temperature sensors connected via 1-Wire interface.

Example:
    >>> from therm import TemperatureCollector
    >>> collector = TemperatureCollector()
    >>> temperatures = collector.read_all_temperatures()
    >>> efficiency = collector.calculate_efficiency(temperatures)
"""

__version__ = "1.0.0"
__author__ = "devoramaMan"
__email__ = "mrandreas@hotmail.com"
__license__ = "MIT"
__description__ = "Temperature monitoring package for DS18B20 sensors in heat exchangers"

# Import main classes
try:
    from .temperature_collector import TemperatureCollector
    __all__ = ["TemperatureCollector"]
except ImportError as e:
    print(f"Warning: Could not import TemperatureCollector: {e}")
    __all__ = []

# Package metadata
__package_info__ = {
    "name": "HeatExchangerMonitor",
    "version": __version__,
    "author": __author__,
    "email": __email__,
    "license": __license__,
    "description": __description__,
}