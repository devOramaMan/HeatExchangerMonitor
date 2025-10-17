#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import importlib.util
from setuptools import setup, find_packages

# Load version from __init__.py
def get_version():
    """Get version from therm/__init__.py"""
    init_path = os.path.join(os.path.dirname(__file__), "therm", "__init__.py")
    spec = importlib.util.spec_from_file_location("version", init_path)
    version_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(version_module)
    return version_module.__version__

# Read README for long description
def get_long_description():
    """Get long description from README.md"""
    readme_path = os.path.join(os.path.dirname(__file__), "README.md")
    try:
        with open(readme_path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "Temperature monitoring package for DS18B20 sensors in heat exchangers"

setup(
    name="HeatExchangerMonitor",
    version=get_version(),
    license="MIT",
    description="Temperature monitoring package for 4x DS18B20 sensors to monitor heat exchanger efficiency",
    long_description=get_long_description(),
    long_description_content_type="text/markdown",
    author="devoramaMan",
    author_email="mrandreas@hotmail.com",
    maintainer="devoramaMan",
    maintainer_email="mrandreas@hotmail.com",
    url="https://github.com/devOramaMan/HeatExchangerMonitor",
    download_url="https://github.com/devOramaMan/HeatExchangerMonitor",
    packages=find_packages(),
    package_data={
        "therm": ["devicenames.json"],
    },
    include_package_data=True,
    entry_points={
        "console_scripts": [
            "heat-exchanger-monitor=therm.temperature_collector:main",
            "therm-collector=therm.temperature_collector:main",
        ],
    },
    install_requires=[
        "w1thermsensor>=1.0.5; platform_system=='Linux'",
    ],
    extras_require={
        "test": ["pytest>=6.0", "pytest-bdd>=6.0", "pytest-mock>=3.0"],
        "dev": ["pytest>=6.0", "pytest-bdd>=6.0", "pytest-mock>=3.0", "black", "flake8"]
    },
    python_requires=">=3.7",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Topic :: System :: Hardware",
        "Topic :: System :: Monitoring",
    ]
)
