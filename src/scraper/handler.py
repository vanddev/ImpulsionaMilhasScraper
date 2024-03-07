import json
from datetime import datetime, timezone
import requests
from bs4 import BeautifulSoup

keywords = ["compre", "transfer", "transfira", "bônus", "bonificada"]
groups = {"smiles": "https://e-milhas.com/c/9-smiles",
          "latampass": "https://e-milhas.com/c/10-latam-pass",
          "tudoazul": "https://e-milhas.com/c/11-tudoazul"}
post_date_format = '%d/%m/%Y'


class BadRequestErrors:
    empty_query_parameter = "The Query Parameter 'airline_group' must be fulfilled"
    invalid_group = "The airline_group informed is invalid"


def get_title(post) -> str:
    return post.h4.a.text


def clean_text(text):
    without_multiply_breaklines = text.splitlines()
    without_multiply_breaklines = map(str.strip, without_multiply_breaklines)
    cleaned = '\r\n\r\n'.join(filter(None, without_multiply_breaklines))
    return cleaned


def extract_opportunity(post):
    op = {
        "title": post.h4.a.text,
        "description": clean_text(post.p.get_text(strip=True)),
        "deadline": post.find_all('small')[0].get_text(strip=True).replace('Até').strip()
    }
    return op


def scrape_portal(group_name, exclude_expired=False):
    url = groups[group_name]
    page = requests.get(url)
    current_date = datetime.now().date()
    soup = BeautifulSoup(page.content, "html.parser")
    posts = soup.find_all('article', class_='post-single')
    opportunities = []
    for post in posts:
        title = get_title(post)
        if any(substring in title.lower() for substring in keywords):
            opportunity = extract_opportunity(post)
            opportunity['group'] = group_name
            deadline = datetime.strptime(opportunity['deadline'], post_date_format).date()
            if current_date < deadline or not exclude_expired:
                opportunities.append(opportunity)
    return opportunities


def build_response(status_code: int, body=None, error: str = None) -> dict:
    return {
        'statusCode': status_code,
        'body': json.dumps(body) if status_code == 200 else error
    }


def validate_input(event) -> dict:
    if (not event['queryStringParameters']) or (not event['queryStringParameters']['group']) or (
            event['queryStringParameters']['group'] is None):
        return build_response(400, error=BadRequestErrors.empty_query_parameter)

    if not event['queryStringParameters']['group'] in groups:
        return build_response(400, error=BadRequestErrors.invalid_group)


def gateway_event_handler(event):
    founded_errors_in_validation = validate_input(event)
    if founded_errors_in_validation:
        return founded_errors_in_validation
    else:
        return build_response(200, scrape_portal(event['queryStringParameters']['group']))


def default_event_handler(event):
    target_groups = event['groups']
    exclude_expired = event['exclude_expired']

    result = []

    for group in target_groups:
        result.append(scrape_portal(group, exclude_expired=exclude_expired))

    flat_ls = [item for sublist in result for item in sublist]
    return flat_ls


def lambda_handler(event, context):
    if 'httpMethod' in event:
        return gateway_event_handler(event)
    return default_event_handler(event)
