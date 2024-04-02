#!/bin/sh

cp /etc/localstack/init/ready.d/mocked_lambda.py mocked_lambda.py
cp /etc/localstack/init/ready.d/dynamo_insert_items.json dynamo_insert_items.json

zip lambda.zip mocked_lambda.py

awslocal  lambda create-function \
          --function-name scraper \
          --runtime python3.12 \
          --role arn:aws:iam::000000000000:role/lambda-ex \
          --handler mocked_lambda.lambda_handler \
          --zip-file fileb://lambda.zip

awslocal dynamodb create-table \
          --table-name OffersHistory \
          --attribute-definitions AttributeName=OriginalURL,AttributeType=S \
          --key-schema AttributeName=OriginalURL,KeyType=HASH \
          --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5

awslocal dynamodb batch-write-item \
          --request-items file://dynamo_insert_items.json