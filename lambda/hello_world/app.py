from azure.cosmos import CosmosClient, PartitionKey
import os
import boto3
from botocore.client import Config
from google.cloud import vision
from google.cloud.vision_v1 import AnnotateImageResponse
from google.oauth2 import service_account
import json
import urllib.parse

ssm = boto3.client('ssm')

cosmosdb_endpoint = ssm.get_parameter(Name='acg_challenge_cosmosdb_endpoint')['Parameter']['Value']
cosmosdb_key = ssm.get_parameter(Name='acg_challenge_cosmosdb_primary_key', WithDecryption=True)['Parameter']['Value']
cosmosdb_database_name = 'acg-multicloud'
cosmosdb_container_name = 'Images'
google_application_credentials = ssm.get_parameter(Name='acg_challenge_service_account', WithDecryption=True)['Parameter']['Value']
upload_bucket_region = ssm.get_parameter(Name='acg_challenge_upload_bucket_region')['Parameter']['Value']

s3 = boto3.client('s3', region_name=upload_bucket_region, config=Config(s3={'addressing_style': 'virtual'}))

service_account_info = json.loads(google_application_credentials)
credentials = service_account.Credentials.from_service_account_info(service_account_info)
vision_client = vision.ImageAnnotatorClient(credentials=credentials)


def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    filename = get_filename(key)

    url = get_presigned_url(bucket, key)

    annotated_image = get_annotated_image(filename, url)

    save_annotated_image_to_cosmosdb(annotated_image)

    return {
        "statusCode": 200,
        "body": "ok"
    }


def get_presigned_url(bucket, key):
    url = s3.generate_presigned_url(
        ClientMethod='get_object',
        Params={
            'Bucket': bucket,
            'Key': key
        }
    )
    return url


def get_annotated_image(filename, url):
    response = vision_client.annotate_image({
        'image': {'source': {
            'image_uri': url}},
        'features': [{'type_': vision.Feature.Type.LANDMARK_DETECTION}, {'type_': vision.Feature.Type.FACE_DETECTION},
                     {'type_': vision.Feature.Type.LABEL_DETECTION}, {'type_': vision.Feature.Type.LOGO_DETECTION},
                     {"type_": vision.Feature.Type.IMAGE_PROPERTIES}, ]
    })
    annotated_image = AnnotateImageResponse.to_dict(response)
    annotated_image['id'] = filename
    annotated_image['url'] = url
    return annotated_image


def get_filename(key):
    return os.path.splitext(key)[0]


def save_annotated_image_to_cosmosdb(annotated_image):
    cosmos_client = CosmosClient(cosmosdb_endpoint, cosmosdb_key)
    database = cosmos_client.create_database_if_not_exists(id=cosmosdb_database_name)
    container = database.create_container_if_not_exists(
        id=cosmosdb_container_name,
        partition_key=PartitionKey(path="/id"),
        offer_throughput=400
    )
    container.create_item(body=annotated_image)
