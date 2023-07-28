import boto3
import json
import os
import re
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info('********************** Environment and Event variables are *********************')
    logger.info(os.environ)
    logger.info(event)

    extract_content(event)

    return {
        'statusCode': 200,
        'body': json.dumps('Execution is now complete')
    }


def convert_pdf_to_json(pdffile):
    """
        Parses and Extracts the metadata (author, title, date-created, description) and contents
        converts them to JSON string
        
    """
    import tika
    from tika import parser
    tika.initVM()    
    tika_output = parser.from_buffer(pdffile)
    metadata = tika_output.get('metadata',{}) 
    title = metadata.get("dc:title","No title")
    created = metadata.get("pdf:docinfo:created","1900/01/01")
    description = metadata.get("dc:description","No Description")
    creator = metadata.get("dc:creator","Unknown Author")
    contents = tika_output.get("content","No Contents")
    #remove duplicate newlines 
    contents = re.sub('[\n]+', '\n', contents)
    output = { "title":title,
        "date_created":created,
        "description":description,
        "author":creator,
        "contents" : contents
    }
    return json.dumps(output,indent=2)


def extract_content(event):
    #Read the target bucket from the lambda environment variable
    targetBucket = os.environ.get('TARGET_BUCKET',"NO_BUCKET")
    print('Target bucket is', targetBucket)

    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    print('The s3 bucket is', bucket, 'and the file name is', key)
    s3client = boto3.client('s3')
    response = s3client.get_object(Bucket=bucket, Key=key)
    pdffile = response["Body"]
    print('The binary pdf file type is', type(pdffile))

    json_output = convert_pdf_to_json(pdffile)
    s3client.put_object(Bucket=targetBucket, Key=key+".json", Body=json_output)

    print('All done, returning from Extract content method')
