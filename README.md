# sample-billing-resources

The billing team's "core" resources: storage and network

A application infrastructure component on AWS, managed with
Terraform.

| Setting           | Value                             |
| ----------------- | --------------------------------- |
| Environment       | `development`       |
| Region            | `us-east-1`            |
| Project           | `acme-billing`       |
| Business unit     | `engineering`      |
| Cost center       | `application-development`        |
| Naming convention | `enterprise`  |

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

Each resource lives in its own file with its variables and outputs, and has a
test file under `tests/`. Change the settings in `terraform.tfvars`.

## Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request:
formatting, validation, TFLint, `terraform test` against mocked providers and a
Trivy scan need no credentials and always run. Plan and Apply are skipped until
the following are configured in the repository settings:

| Name | Kind | Purpose |
| ---- | ---- | ------- |
| `AWS_ROLE_ARN` | secret | IAM role the workflow assumes through GitHub OIDC |
| `TF_STATE_BUCKET` | secret | S3 bucket that stores the state |
| `TF_STATE_REGION` | variable | Region of that bucket; optional, defaults to `us-east-1` |

## State

The state is kept in an S3 bucket; `backend.tf` sets its path
inside the bucket (hierarchical layout).
Each environment uses its own Terraform workspace; the pipeline selects the
workspace `development`.
State locking is on.

## Working locally

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

See `docs/index.md` for details.
