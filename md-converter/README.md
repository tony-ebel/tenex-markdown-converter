# Md Converter
This python code is triggered by a pubsub topic and converts
markdown in the payload to html. Then uploads that to a GCS bucket
specified in the payload.

# Deploying
To manually deploy run the following

```bash
gcloud functions deploy md_converter \
  --runtime python312 \
  --trigger-topic mdconversions \
  --entry-point pubsub_trigger \
  --region us-central1 \
  --project still-tower-474715-c6 \
  --source .
```
