resource "aws_codepipeline" "this" {
  name          = local.codepipeline_name
  role_arn      = aws_iam_role.cp.arn
  pipeline_type = "V2"
  variable {
    name          = "TARGET_ROLE_ARN"
    default_value = "arn:aws:iam::${var.target_account}:role/${var.target_account_role}"
  }
  variable {
    name          = "TFSTATE_BUCKET_NAME"
    default_value = local.tfstate_bucket_name
  }
  variable {
    name          = "TFSTATE_FILE_NAME"
    default_value = var.tfstate_file_name
  }
  variable {
    name          = "TARGET_ROLE_SESSION"
    default_value = var.target_account_role_session
  }
  variable {
    name          = "TF_ACTION"
    default_value = "apply"
  }


  artifact_store {
    location = aws_s3_bucket.this[var.cicd_bucket_suffix].id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        S3Bucket    = local.cicd_bucket_name
        S3ObjectKey = var.input_artifact
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      version         = "1"

      configuration = {
        ProjectName          = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode(local.codepipeline_env_vars)
      }

    }
  }

  depends_on = [
    aws_s3_object.this
  ]
}

