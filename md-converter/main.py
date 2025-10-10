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
    try:
        pubsub_message = cloud_event.data["message"]

        if pubsub_message.get('data'):
            data_bytes = base64.b64decode(pubsub_message['data'])
            data_str = data_bytes.decode('utf-8')

            payload = json.loads(data_str)

            markdown = payload.get("markdown", None)
            job_id = payload.get("jobid", None)
            bucket_name = payload.get("bucketname", None)

            html = markdown_to_html(markdown)
            html_to_gcs(html, job_id, bucket_name)


    except Exception as e:
        print(f'An error occured: {e}')
