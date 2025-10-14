# Md Converter
This python code is triggered by a pubsub topic and converts
markdown in the payload to html. Then uploads that to a GCS bucket
specified in the payload.

# Deploying
Deploys are managed by a github actions [workflow](../.github/workflows/deploy-function.yml)

To deploy to a specified environment:
 - stage: merge into `main` branch
 - prod: tag with a `v-*` format

*Note*: the workflow will only trigger if code has been changed in this directory
