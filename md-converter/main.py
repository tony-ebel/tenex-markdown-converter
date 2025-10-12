import base64
import json
import markdown
from google.cloud import storage
import functions_framework

def markdown_to_html(md):
    html = markdown.markdown(md)
    return html

def html_to_gcs(html, message_id, bucket_name):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob_name = f'{message_id}.html'
    blob = bucket.blob(blob_name)

    blob.upload_from_string(html)
    print(f'HTML uploaded to gs://{bucket_name}/{blob_name}')


@functions_framework.cloud_event
def pubsub_trigger(cloud_event):
    message_id = None
    bucket_name = None
    try:
        message_id = cloud_event.data['message']['messageId']
        attributes = cloud_event.data['message']['attributes']

        bucket_name = attributes.get("bucketname")

    except (KeyError, AttributeError) as e:
        print(f"Error accessing message data or attributes: {e}")
        return

    markdown = None
    if cloud_event.data['message']['data']:
        markdown = base64.b64decode(cloud_event.data['message']['data']).decode('utf-8')

    if not bucket_name:
        print("Error: 'bucketname' attribute missing.")
        return

    if not markdown:
        print("Error: Message data is empty or could not be decoded.")
        return

    html = markdown_to_html(markdown)
    html_to_gcs(html, message_id, bucket_name)
