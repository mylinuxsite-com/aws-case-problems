variable "cicd_bucket_suffix" {
  type        = string
  default     = "cicd"
  description = "The suffix of the CiCd S3 bucket name. The value will be appended to the pipeline_name to form the S3 bucket name."
}

variable "tfstate_bucket_suffix" {
  type        = string
  default     = "tf-state"
  description = "The suffix of the State S3 bucket name. The value will be appended to the pipeline_name to form the S3 bucket name."
}

variable "tfstate_file_name" {
  type        = string
  default     = "cross-account.tfstate"
  description = "The name of the Terraform tfstate file stored in S3."
}

variable "target_account" {
  type        = string
  description = "The target account."
}

variable "target_account_role" {
  type        = string
  default     = "cicd-cross-account-role"
  description = "The target account role that will access the TF state S3 bucket."
}

variable "target_account_role_session" {
  type        = string
  default     = "CodeBuild"
  description = "The session name of target account role that will access the TF state S3 bucket."
}

variable "pipeline_name" {
  type        = string
  default     = "TerraformCrossAccount"
  description = "The name of the pipeline."
}

variable "input_artifact" {
  type        = string
  default     = "input-artifact.zip"
  description = "The name of the input artifact."
}