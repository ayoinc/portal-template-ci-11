# sample-billing-resources

The billing team's "core" resources: storage and network

## Overview

This repository holds one application infrastructure component on
AWS for the `development` environment in `us-east-1`. It is
described in Terraform, tested without cloud access and deployed by GitHub
Actions.

| Setting           | Value                             |
| ----------------- | --------------------------------- |
| Component type    | `application`     |
| Project           | `acme-billing`       |
| Business unit     | `engineering`      |
| Cost center       | `application-development`        |
| Application ID    | `app-1234`     |
| Owner             | `group:default/platform-team`             |
| Naming convention | `enterprise`  |
| Secondary region  | `us-west-2`   |

## Resources

| Resource | Included | What is created |
| -------- | -------- | --------------- |
| Resource container | yes | AWS resource group that collects the component's resources by tag |
| Object storage | yes | S3 bucket: versioned, encrypted with its own KMS key, no public access, TLS only; replicated to `us-west-2` |
| Virtual network | yes | VPC with two public and two private subnets in two zones, NAT gateway |
| Key management | yes | KMS key with yearly rotation and an alias |
| Container registry | yes | ECR repository: immutable tags, scan on push, old images expire |
| Log workspace | yes | CloudWatch log group with retention |
| Virtual machine | yes | EC2 instance (Amazon Linux 2023) in a private subnet, reached with Session Manager |

Every resource is defined in its own file (`storage.tf`, `network.tf`,
`key_vault.tf`, `registry.tf`, `logs.tf`, `vm.tf`) together with the variables
that tune it and its outputs. Files of resources that were not selected are not
part of this repository.

## Names and Tags

`modules/naming` builds every resource name from the convention chosen for this
component:

| Convention   | Pattern                                 |
| ------------ | --------------------------------------- |
| `enterprise` | company-project-environment-type-number |
| `team`       | team-project-type-environment-number    |
| `project`    | project-type-environment-number         |

The company is `example-org`, the team is the business unit, and the
environment is shortened to `dev`, `stg` or `prod`. Names that a service limits
in length are shortened and get a hash; names that must be unique across
AWS get a random suffix.

`modules/tagging` produces the tags every resource carries: component, component
type, project, environment, business unit, cost center, owner, application ID and
`ManagedBy = terraform`.

## Automatic Shutdown

Outside production the virtual machine is stopped on the schedule
`0 19 * * 1-5` (UTC), set as `auto_shutdown_schedule` in
`terraform.tfvars`.
Production machines are never stopped automatically. Start a stopped machine
from the AWS console or CLI.

## Changing the Component

Edit `terraform.tfvars` and push. Settings with defaults are declared at the
top of each resource file, for example `log_retention_days` in `logs.tf`.

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main`, on pull
requests and on demand.

| Job           | What it does                                                                  | Needs credentials |
| ------------- | ----------------------------------------------------------------------------- | ----------------- |
| Validate      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` | No                |
| Lint          | TFLint with the Terraform and AWS rule sets                          | No                |
| Test          | `terraform test` for the naming and tagging modules and for the component, against mocked providers | No |
| Security scan | Trivy on the Terraform code; fails on HIGH and CRITICAL findings              | No                |
| Plan          | `terraform plan` against the state backend                                    | Yes               |
| Apply         | `terraform apply` of that plan, on pushes to `main`                           | Yes               |

Plan and Apply are skipped, not failed, until all of these are configured under
Settings > Secrets and variables > Actions:

| Name | Kind | Purpose |
| ---- | ---- | ------- |
| `AWS_ROLE_ARN` | secret | IAM role the workflow assumes through GitHub OIDC |
| `TF_STATE_BUCKET` | secret | S3 bucket that stores the state |
| `TF_STATE_REGION` | variable | Region of that bucket; optional, defaults to `us-east-1` |

Apply runs in the GitHub environment `development`. Add required
reviewers to that environment to approve each apply by hand. Start the workflow
manually with the action `destroy` to remove the component.

## State

The state is kept in an S3 bucket; `backend.tf` sets its path
inside the bucket (hierarchical layout).
Each environment uses its own Terraform workspace; the pipeline selects the
workspace `development`.
State locking is on.

## Working Locally

These checks need Terraform 1.10 or later and no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

## Repository Structure

```
sample-billing-resources/
├── .github/workflows/terraform.yaml   # Validation and deployment pipeline
├── docs/index.md                      # This documentation
├── modules/naming/                    # Naming conventions
├── modules/tagging/                   # Standard tags and labels
├── tests/                             # Terraform tests against mocked providers
├── backend.tf                         # State backend
├── main.tf                            # Naming, tagging and the resource container
├── providers.tf
├── terraform.tfvars                   # The settings of this component
├── variables.tf
├── versions.tf
├── outputs.tf
├── .tflint.hcl                        # TFLint configuration
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```
