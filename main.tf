terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# S3 Bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "obsidian_sync" {
  bucket = var.bucket_name

  tags = var.tags
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "obsidian_sync" {
  bucket = aws_s3_bucket.obsidian_sync.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "obsidian_sync" {
  bucket = aws_s3_bucket.obsidian_sync.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption with SSE-S3 (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "obsidian_sync" {
  bucket = aws_s3_bucket.obsidian_sync.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle rule: transition noncurrent versions to Glacier Deep Archive,
# then permanently delete them to control long-term costs.
resource "aws_s3_bucket_lifecycle_configuration" "obsidian_sync" {
  bucket = aws_s3_bucket.obsidian_sync.id

  # Versioning must be enabled before lifecycle rules are applied.
  depends_on = [aws_s3_bucket_versioning.obsidian_sync]

  rule {
    id     = "noncurrent-version-management"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_glacier_days
      storage_class   = "DEEP_ARCHIVE"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

# ---------------------------------------------------------------------------
# IAM User, Policy, and Access Key
# ---------------------------------------------------------------------------

resource "aws_iam_user" "obsidian_sync" {
  name = var.iam_user_name

  tags = var.tags
}

data "aws_iam_policy_document" "obsidian_sync" {
  statement {
    sid    = "AllowListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.obsidian_sync.arn,
    ]
  }

  statement {
    sid    = "AllowObjectOperations"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.obsidian_sync.arn}/*",
    ]
  }
}

resource "aws_iam_user_policy" "obsidian_sync" {
  name   = "obsidian-remotely-save-policy"
  user   = aws_iam_user.obsidian_sync.name
  policy = data.aws_iam_policy_document.obsidian_sync.json
}

resource "aws_iam_access_key" "obsidian_sync" {
  user = aws_iam_user.obsidian_sync.name
}
