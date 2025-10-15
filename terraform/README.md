# Terraform
terraform for the Markdown to HTML project in GCP

# Terraform and Tofu
Terraform is the IaC language used to manage our infrastructure.
HashiCorp pivoted the Terraform binary to be a paid tool past version 1.5.7
[OpenTofu](https://opentofu.org/) is a fork of the Terraform binary that is "forever free" and open
source. We will continue to call the code `Terraform` in this repo, but it will
actually need to run via the `tofu` binary.

# Installing Tofu
The recommended way to install tofu is with tofuenv: `winget install tofuenv`
This is because terraform state files cannot be modified by older versions than
the last one used. So if someone accidentally upgrades tofu and modifies the
state file, then others will need to upgrade their tofu binary as well.

You can use tofuenv to install the correct tofu version used in this
repo: `tofuenv install 1.6.0`
Finally have tofuenv set the tofu version to use: `tofuenv use 1.6.0`

# Authorize gcloud
Tofu needs gcloud configured to be used locally. To do this run: `gcloud auth login`

# Initializing Tofu
Before running tofu you'll need to initialize it `tofu init`. This will download
any required providers in `providers.tf`. If the `.terraform` directory is ever
deleted or a provider is changed, you'll need to run `tofu init` again.

# Tofu plan/apply
1. `tofu plan` will create an execution plan, which lets you preview the changes that Tofu plans to make to the infrastructure.
2. `tofu apply` will also create an execution plan, then execute those actions in the plan against our infrastructure. After the plan, you will be prompted to review and type "yes" to apply.

*Note*: you should not manually `tofu apply` unless you know what you're doing.
There are Github Actions setup to run `tofu plan` and `tofu apply` that should
be used instead.

# Targets
If you'd like to run tofu against a specific resource (or set of resources),
you can use the [target](https://opentofu.org/docs/cli/commands/plan/#resource-targeting) parameter. 

Example: `tofu plan -target 'google_pubsub_topic.mdconversions["stage"]'`

# pre-commit (optional)
There are pre-commit hooks setup for tofu in this repo
1. install pre-commit: `winget install pre-commit`
2. setup hooks on each commit with: `pre-commit install`

