import requests
from bs4 import BeautifulSoup

keywords = ["compre", "transfer", "transfira", "bônus", "bonificada"]
oportunities = []


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
        "deadline": post.find_all('small')[0].get_text(strip=True)
    }
    return op


def main():
    URL = "https://e-milhas.com/c/9-smiles"
    page = requests.get(URL)

    soup = BeautifulSoup(page.content, "html.parser")
    posts = soup.find_all('article', class_='post-single')
    for post in posts:
        title = get_title(post)
        if any(substring in title.lower() for substring in keywords):
            opportunity = extract_opportunity(post)
            oportunities.append(opportunity)


if __name__ == '__main__':
    main()
    # print(content.prettify())
