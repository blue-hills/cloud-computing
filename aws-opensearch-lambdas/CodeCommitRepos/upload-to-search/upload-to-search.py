import boto3
import re
import os
import requests
import json
from requests_aws4auth import AWS4Auth

region = 'us-east-1'  
service = 'es'
credentials = boto3.Session().get_credentials()

awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)
print("Credentials access key:", credentials.access_key)
print("Credentials secret key:", credentials.secret_key)

host = os.environ.get('SEARCH_DOMAIN',None)
if not host:
    print("Environment variable: SEARCH_DOMAIN not defined")
    
index = 'taxforms'
datatype = '_doc'
url = host + '/' + index + '/' + datatype

headers = { "Content-Type": "application/json" }

s3 = boto3.client('s3')

# Lambda execution starts here
def handler(event, context):
    for record in event['Records']:

        # Get the bucket name and key for the new file
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        # Get, read, and split the file into lines
        obj = s3.get_object(Bucket=bucket, Key=key)
        body = obj['Body'].read()
        document = json.loads(body)
        
        print("Document:",document)
        r = requests.post(url, auth=awsauth, json=document, headers=headers)
        print("Response:", r.text)
