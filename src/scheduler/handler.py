import json
import os
from datetime import datetime
import requests
import boto3

FUNCTION_SCRAPER = os.getenv('LAMBDA_SCRAPER_ARN')
OFFERS_TABLE_NAME = os.getenv('NEWEST_OFFERS_TABLE')
lambda_client = boto3.client('lambda')
dynamo_client = boto3.client('dynamodb')
groups = ["smiles", "latampass", "tudoazul"]
post_date_format = '%d/%m/%Y'
NOTIFICATOR_URL = ''


def save_offers(scraper_result):
    for offer in scraper_result:
        dynamo_client.put_item(
            TableName=OFFERS_TABLE_NAME,
            Item={
                'Title': {
                    'S': offer['title']
                },
                'Description': {
                    'S': offer['description']
                },
                'Group': {
                    'S': offer['group']
                },
                'Deadline': {
                    'S': offer['deadline']
                },
                'ExpirationDate': {
                    'N': datetime.strptime(offer['deadline'], post_date_format).timestamp()
                }
            }
        )


def parse_offers_to_keys(offers):
    return list(map(lambda item: {'title': {'S': item['Title']}}, offers))


def parse_datas_to_offers(datas):
    return list(map(lambda item: {
        'title': item['Title']['S'],
        'description': item['Description']['S'],
        'group': item['Group']['S'],
        'deadline': item['Deadline']['S']
    }, datas))


def get_sent_offers_diff(offers):
    response = parse_datas_to_offers(dynamo_client.batch_get_item(
        RequestItems={
            OFFERS_TABLE_NAME: {
                'Keys': parse_offers_to_keys(offers)
            }
        }
    )['Responses'][OFFERS_TABLE_NAME])
    offers_diff = [offer for offer in offers if offer not in response]
    return offers_diff


def send_offers_to_subscribers(offers_to_send):
    for offer in offers_to_send:
        requests.post(NOTIFICATOR_URL, data=offer)


def lambda_handler(event, context):
    scraper_result = lambda_client.invoke(
        FunctionName=FUNCTION_SCRAPER,
        Payload=json.dumps({"exclude_expired": False, "groups": groups})
    )
    offers_to_send = get_sent_offers_diff(scraper_result)
    send_offers_to_subscribers(offers_to_send)
    save_offers(offers_to_send)
