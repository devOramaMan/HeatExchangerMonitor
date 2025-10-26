

import asyncio
from datetime import datetime
from azure.messaging.webpubsubservice import WebPubSubServiceClient
import logging
import websockets

log = logging.getLogger(__name__)

class TemperaturePublisher:
    """
    TemperaturePublisher publishes temperature data to Azure Web PubSub service.
    """

    def __init__(self, connection_string: str, hub_name: str):
        """
        Initialize the TemperaturePublisher
        
        Args:
            connection_string: Azure Web PubSub connection string
            hub_name: Name of the Web PubSub hub
        """
        self.client = WebPubSubServiceClient.from_connection_string(
            connection_string, hub=hub_name
        )
        self.hub_name = hub_name

    def publish_temperature(self, temperatures: dict):
        """
        Publish temperature data to the Web PubSub service
        
        Args:
            temperatures: Dictionary of temperature readings
        """
        if len(temperatures) < 4:
            print("Insufficient temperature data to publish.")
            return
        
        message = {
            "data": {
                "temp1": temperatures['T1'],
                "temp2": temperatures['T2'],
                "temp3": temperatures['T3'],
                "temp4": temperatures['T4'],
                "timestamp": datetime.now().isoformat(),#'2025-10-26T17:10:47.757Z'
                },
            "type": 'temperature_message'
        }        
        
        self.client.send_to_all(message)
        log.debug(f"Published temperatures to {self.hub_name}")


async def connect(url):
    async with websockets.connect(url) as ws:
        log.info('connected')
        while True:
            log.info('Received message: ' + await ws.recv())

class TemperatureSubscriber:
    """
    TemperatureSubscriber subscribes to temperature data from Azure Web PubSub service.
    """

    def __init__(self, connection_string: str, hub_name: str):
        """
        Initialize the TemperatureSubscriber
        
        Args:
            connection_string: Azure Web PubSub connection string
            hub_name: Name of the Web PubSub hub
        """
        self.client = WebPubSubServiceClient.from_connection_string(
            connection_string, hub=hub_name
        )
        self.hub_name = hub_name

    def receive_temperature(self, receiveClb = connect ):
        """
        Receive temperature data from the Web PubSub service
        """
        # Implementation for receiving messages would go here
        token = self.client.get_client_access_token()
        try:
            asyncio.get_event_loop().run_until_complete(receiveClb(token['url']))
        except KeyboardInterrupt:
            pass