
import logging
import json
from therm.temperature_collector import TemperatureCollector
from publisher.temperature_PubSub import TemperaturePublisher


log = logging.getLogger("HeatExchangerMonitor")

#main
if __name__ == "__main__":
    """Main function"""
    #init logger with console output 
    # set logger format 
    logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
    # output to console
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    logging.getLogger().addHandler(console_handler)


    try:
        # Read secrets
        with open("secrets.json") as f:
            secrets = json.load(f)
            
        connection_string = secrets.get("AZURE_WEBPUBSUB_CONNECTION_STRING")

        # Initialize collector
        collector = TemperatureCollector()

        # Init publisher
        publisher = TemperaturePublisher( 
            connection_string=connection_string,
            hub_name="heat_exchanger_hub"
        )
        # start monitor thread
        collector.monitor_continuous(interval=5, callback=publisher.publish_temperature)


    except Exception as e:
        log.error(f"Error in temperature collection: {e}")

