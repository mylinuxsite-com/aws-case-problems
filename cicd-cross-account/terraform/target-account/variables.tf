variable "tfstate_bucket_suffix" {
  type        = string
  default     = "tf-state"
  description = "The suffix of the Terraform State S3 bucket. The value will be appended to the pipeline_name to form the S3 bucket name."
}

variable "tfstate_file_name" {
  type        = string
  default     = "cross-account.tfstate"
  description = "The name of the Terraform tfstate file stored in S3."
}

variable "account_role" {
  type        = string
  default     = "cicd-cross-account-role"
  description = "The account role that will access the TF state bucket."
}

variable "account_role_session" {
  type        = string
  default     = "CodeBuild"
  description = "The session name of used to assume the role that will access the TF state bucket."
}

variable "cicd_account" {
  type        = string
  description = "The CiCd account."
}

variable "pipeline_name" {
  type        = string
  default     = "TerraformCrossAccount"
  description = "The name of the pipeline."
}

