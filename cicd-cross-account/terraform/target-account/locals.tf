locals {
  tfstate_bucket_name = lower("${var.pipeline_name}-${var.tfstate_bucket_suffix}")
}