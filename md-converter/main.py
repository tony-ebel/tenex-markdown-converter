import base64
import json
import markdown
from google.cloud import storage
import functions_framework

def markdown_to_html(md):
    html = markdown.markdown(md)
    return html

def html_to_gcs(html, job_id, bucket_name):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob_name = f'{job_id}.html'
    blob = bucket.blob(blob_name)

    blob.upload_from_string(html)
    print(f'HTML uploaded to gs://{bucket_name}/{blob_name}')


@functions_framework.cloud_event
def pubsub_trigger(cloud_event):
    job_id = None
    bucket_name = None
    try:
        attributes = cloud_event.data['message']['attributes']

        job_id = attributes.get("jobid")
        bucket_name = attributes.get("bucketname")

    except (KeyError, AttributeError):
        print('Message attributes not found or incorrectly structured.')

    markdown = None
    if cloud_event.data['message']['data']:
        markdown = base64.b64decode(cloud_event.data['message']['data']).decode('utf-8')

    html = markdown_to_html(markdown)
    html_to_gcs(html, job_id, bucket_name)
