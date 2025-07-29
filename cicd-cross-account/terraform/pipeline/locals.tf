data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

locals {
  region              = data.aws_region.this.id
  account             = data.aws_caller_identity.this.account_id
  codebuild_name      = "${var.pipeline_name}-CodeBuild"
  codepipeline_name   = "${var.pipeline_name}-CodePipeline"
  cicd_bucket_name    = aws_s3_bucket.this[var.cicd_bucket_suffix].id
  tfstate_bucket_name = aws_s3_bucket.this[var.tfstate_bucket_suffix].id
  input_artifacts_dir = "${path.module}/../artifacts/input"
  codepipeline_env_vars = [
    {
      name  = "TFSTATE_BUCKET_NAME",
      value = "#{variables.TFSTATE_BUCKET_NAME}",
      type  = "PLAINTEXT"
    },
    {
      name  = "TFSTATE_FILE_NAME",
      value = "#{variables.TFSTATE_FILE_NAME}",
      type  = "PLAINTEXT"
    },
    {
      name  = "TARGET_ROLE_ARN",
      value = "#{variables.TARGET_ROLE_ARN}",
      type  = "PLAINTEXT"
    },
    {
      name  = "TARGET_ROLE_SESSION",
      value = "#{variables.TARGET_ROLE_SESSION}",
      type  = "PLAINTEXT"
    },
    {
      name  = "TF_ACTION",
      value = "#{variables.TF_ACTION}",
      type  = "PLAINTEXT"
    }
  ]
}