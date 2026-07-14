output "bucket_name" {
  description = "Name of the S3 bucket. Paste this into the Remotely Save plugin 'S3 Bucket Name' field."
  value       = aws_s3_bucket.obsidian_sync.bucket
}

output "aws_region" {
  description = "AWS region of the S3 bucket. Paste this into the Remotely Save plugin 'S3 Region' field."
  value       = var.aws_region
}

output "access_key_id" {
  description = "IAM Access Key ID. Paste this into the Remotely Save plugin 'S3 Access Key ID' field."
  value       = aws_iam_access_key.obsidian_sync.id
}

output "secret_access_key" {
  description = "IAM Secret Access Key. Paste this into the Remotely Save plugin 'S3 Secret Access Key' field."
  value       = aws_iam_access_key.obsidian_sync.secret
  sensitive   = true
}
