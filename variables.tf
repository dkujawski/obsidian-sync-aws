variable "aws_region" {
  description = "AWS region where the S3 bucket will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Obsidian vault sync. Must be globally unique."
  type        = string
}

variable "iam_user_name" {
  description = "Name of the IAM user created for the Obsidian Remotely Save plugin."
  type        = string
  default     = "obsidian-remotely-save"
}

variable "noncurrent_version_glacier_days" {
  description = "Number of days after which noncurrent object versions are transitioned to Glacier Deep Archive."
  type        = number
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which noncurrent object versions are permanently deleted."
  type        = number
  default     = 180
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default = {
    Project   = "obsidian-sync"
    ManagedBy = "terraform"
  }
}
