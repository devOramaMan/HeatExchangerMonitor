Feature: Temperature Collector
  As a heat exchanger monitoring system
  I want to collect temperature readings from DS18B20 sensors
  So that I can calculate the heat exchanger efficiency

  Background:
    Given I have a temperature collector with mock sensors
    And the sensors are configured with test device IDs

  Scenario: Initialize temperature collector in mock mode
    When I initialize the temperature collector
    Then it should be in mock mode
    And it should have 4 sensors configured
    And sensor "T1" should be available

  Scenario: Read temperature from a single sensor
    Given I have an initialized temperature collector
    When I read temperature from sensor "T1"
    Then I should get a valid temperature reading
    And the temperature should be between 0 and 100 degrees

  Scenario: Read temperatures from all sensors
    Given I have an initialized temperature collector
    When I read temperatures from all sensors
    Then I should get readings from 4 sensors
    And all sensor readings should be valid floats
    And sensors "T1", "T2", "T3", "T4" should all have readings

  Scenario: Calculate heat exchanger efficiency with valid temperatures
    Given I have temperature readings:
    When I calculate the efficiency
    Then the efficiency should be approximately 57.1 percent

  Scenario: Handle missing sensor data for efficiency calculation
    Given I have incomplete temperature readings:
    When I calculate the efficiency
    Then the efficiency should be None

  Scenario: Handle zero temperature difference
    Given I have temperature readings with zero difference:
    When I calculate the efficiency
    Then the efficiency should be None

  Scenario: Handle invalid sensor reading
    Given I have an initialized temperature collector
    When I try to read from invalid sensor "T999"
    Then the reading should be None

  Scenario: Test mock sensor functionality
    Given I have a mock DS18B20 sensor with ID "test_id"
    When I get the temperature reading
    Then the temperature should be a valid float
    And the temperature should be between -50 and 150 degrees

  Scenario: Test temperature consistency for specific sensors
    Given I have a mock DS18B20 sensor with ID "32323232323232"
    When I get the temperature reading
    Then the temperature should be between 80 and 90 degrees
    
  Scenario: Test cold sensor temperature consistency
    Given I have a mock DS18B20 sensor with ID "567890123456789"
    When I get the temperature reading
    Then the temperature should be between 10 and 20 degrees