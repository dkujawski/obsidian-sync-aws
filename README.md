# obsidian-sync-aws

Terraform configuration that provisions the AWS infrastructure required to sync an [Obsidian](https://obsidian.md/) vault across devices using the [Remotely Save](https://github.com/remotely-save/remotely-save) plugin and Amazon S3.

---

## What this creates

| Resource | Description |
|---|---|
| **S3 Bucket** | Private bucket with versioning, SSE-S3 encryption, Block Public Access, and a lifecycle rule that moves noncurrent versions to Glacier Deep Archive after 90 days and deletes them after 180 days. |
| **IAM User** | Dedicated user (`obsidian-remotely-save` by default) with least-privilege inline policy scoped to the bucket. |
| **IAM Access Key** | Access Key ID / Secret used by the plugin. |

---

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
* An AWS account with credentials that have permission to create S3 buckets and IAM resources (e.g. `AdministratorAccess` or a scoped policy).
* AWS credentials exported in the environment or configured in `~/.aws/credentials`:

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"   # optional – overridden by var.aws_region
```

---

## Usage

### 1. Clone and enter the directory

```bash
git clone https://github.com/dkujawski/obsidian-sync-aws.git
cd obsidian-sync-aws
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan (dry-run)

```bash
terraform plan -var="bucket_name=my-obsidian-vault-sync"
```

Replace `my-obsidian-vault-sync` with a **globally unique** S3 bucket name.

### 4. Apply

```bash
terraform apply -var="bucket_name=my-obsidian-vault-sync"
```

Terraform will prompt for confirmation. Type `yes` to proceed.

### 5. Retrieve the plugin credentials

After a successful apply, retrieve the sensitive output values:

```bash
terraform output bucket_name
terraform output aws_region
terraform output access_key_id
terraform output -raw secret_access_key
```

> **Security note:** The `secret_access_key` output is marked `sensitive`. Terraform will not print it automatically; you must use `-raw` to retrieve it. Store it securely and never commit it to version control.

---

## Configuring the Remotely Save plugin

1. In Obsidian, open **Settings → Community Plugins → Remotely Save → Settings**.
2. Set **Remote Service** to **S3 or compatible**.
3. Fill in the fields:
   | Plugin field | Terraform output |
   |---|---|
   | S3 Bucket Name | `bucket_name` |
   | S3 Region | `aws_region` |
   | S3 Access Key ID | `access_key_id` |
   | S3 Secret Access Key | `secret_access_key` |
4. Leave **Endpoint** blank to use the default AWS endpoint.
5. Click **Check** to verify the connection, then enable **Auto sync**.

---

## Input variables

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region for the bucket. |
| `bucket_name` | *(required)* | Globally unique S3 bucket name. |
| `iam_user_name` | `obsidian-remotely-save` | IAM user name. |
| `noncurrent_version_glacier_days` | `90` | Days before noncurrent versions move to Glacier Deep Archive. |
| `noncurrent_version_expiration_days` | `180` | Days before noncurrent versions are permanently deleted. |
| `tags` | `{Project="obsidian-sync", ManagedBy="terraform"}` | Tags applied to all resources. |

---

## Tear-down

```bash
terraform destroy -var="bucket_name=my-obsidian-vault-sync"
```

> **Warning:** Destroying the stack will delete the IAM user and its access key. The S3 bucket must be **empty** before Terraform can delete it. Empty the bucket first, or set the `force_destroy` argument if you add it to your configuration.

---

## Security considerations

* The IAM policy follows the **principle of least privilege**: only `s3:ListBucket`, `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` are granted, strictly scoped to the single bucket.
* All objects are encrypted at rest with SSE-S3 (AES-256).
* All public access to the bucket is explicitly blocked.
* The `secret_access_key` Terraform output is marked `sensitive` and will not appear in plan/apply output.
* `.tfvars` files and state files are excluded from version control via `.gitignore`; store remote state (e.g. S3 backend) for production use.