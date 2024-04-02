import json
import os
from datetime import datetime
import requests
import boto3
import logging

FUNCTION_SCRAPER = os.getenv('LAMBDA_SCRAPER_ARN')
OFFERS_TABLE_NAME = os.getenv('NEWEST_OFFERS_TABLE')
NOTIFICATOR_URL = os.getenv('NOTIFICATOR_URL')
lambda_client = boto3.client('lambda')
dynamo_client = boto3.client('dynamodb')
groups = ["smiles", "latampass", "tudoazul"]
post_date_format = '%d/%m/%Y'
logger = logging.getLogger(__name__)


def save_offers(offers):
    if offers:
        put_items = list(map(lambda item: {
            'PutRequest': {
                'Item': {
                    'Title': {
                        'S': item['title']
                    },
                    'Group': {
                        'S': item['group']
                    },
                    'OriginalURL': {
                        'S': item['original_url']
                    },
                    'Deadline': {
                        'S': item['deadline']
                    },
                    'ExpirationDate': {
                        'N': str(int(datetime.strptime(item['deadline'], post_date_format).timestamp()))
                    }
                }
            }
        }, offers))
        dynamo_client.batch_write_item(
            RequestItems={
                OFFERS_TABLE_NAME: put_items
            }
        )


def parse_offers_to_keys(offers):
    return list(map(lambda item: {'OriginalURL': {'S': item['original_url']}}, offers))


def parse_datas_to_offers(datas):
    return list(map(lambda item: {
        'title': item['Title']['S'],
        'group': item['Group']['S'],
        'deadline': item['Deadline']['S'],
        'original_url': item['OriginalURL']['S']
    }, datas))


def get_sent_offers_diff(offers):
    keys = parse_offers_to_keys(offers)
    data = dynamo_client.batch_get_item(
        RequestItems={
            OFFERS_TABLE_NAME: {
                'Keys': keys
            }
        }
    )['Responses'][OFFERS_TABLE_NAME]

    response = parse_datas_to_offers(data)
    offers_diff = [offer for offer in offers if offer not in response]
    return offers_diff


def send_offers_to_subscribers(offers_to_send) -> bool:
    # since the telegram is on back4app, its good check app's health to wake apps up
    response = requests.get(f"{NOTIFICATOR_URL}/health")
    if response.status_code != 200:
        logger.warning(f"Error on connect to {NOTIFICATOR_URL}")
        return False
    offers_group = split_offers_by_groups(offers_to_send)
    for offers in offers_group:
        response = requests.post(f"{NOTIFICATOR_URL}/broadcast/subscribed?group={offers[0]['group']}", json=offers)
        if response.status_code != 200:
            logger.warning(f"Error on send broadcast message to offers {offers}")
            return False
    return True


def split_offers_by_groups(offers):
    airline_groups = list(map(lambda item: item['group'], offers))
    offers_by_group = []
    for group in airline_groups:
        offers_by_group.append(list(filter(lambda item: item['group'] == group, offers)))
    return offers_by_group


def lambda_handler(event, context):
    response = lambda_client.invoke(
        FunctionName=FUNCTION_SCRAPER,
        Payload=json.dumps({"exclude_expired": False, "groups": groups})
    )
    response_payload = json.load(response['Payload'])
    offers_to_send = get_sent_offers_diff(response_payload)
    if send_offers_to_subscribers(offers_to_send):
        save_offers(offers_to_send)
