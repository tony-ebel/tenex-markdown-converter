# Markdown to HTML Converter
This repo contains an application that converts markdown to html.


## md-converter
Directory that contains the python Cloud Function that converts markdown to html.

The deployments for this Cloud Function are handled by a Github Action [here](.github/workdflows/deploy-function.yml)

#### Deployments
- stage: merges into `main` branch
- prod: semver tags created

*Note*: The Cloud Functions are not managed by terraform as they do not work well
with our continuous deployments. The service accounts that the Cloud Functions
use are however managed in our terraform.

## md-website
Directory containing the flask application that serves out our website to the client.
It also handles API requests from the client for conversions of markdown, as well
as returns the converted html back to the client.

#### CI
There is a CI Github Actions Workflow [here](.github/workflows/main.yml) that
will run whenever a PR is opened against `main`. The workflow will build the
docker container as well as run linting and formatting with `ruff`. These jobs
will need to pass before PRs are allowed to merge into `main`.

The deployments for the Cloud Run Services are handled by a Github Action [here](.github/workdflows/deploy-services.yml)

#### Deployments
- stage: merges into `main` branch
- prod: semver tags created

## terraform
Directory containing terraform for all infrastructure related to the Markdown
to HTML Converter.

There is a Github Actions Workflow [here](.github/workflows/terraform-plan.yml) that will run whenever a PR
is opened against `main`. This workflow will test formating, validation, and run
a plan and then return the output to a comment in the PR. These jobs will need to
pass before merges are allowed into `main`.

#### Tofu
While the directory is called terraform, and documents mention terraform, the
binary we use is [OpenTofu](https://opentofu.org/)

#### Deployments
Deployments are manged by a Github Actions Workflow [here](.github/workflows/terraform-apply.yml)

*Note*: terraform deployments are done manually by triggering the workflow and
only run against the `main` branch.
