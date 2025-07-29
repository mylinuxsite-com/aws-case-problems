#Codebuild IAMs
resource "aws_codebuild_project" "this" {
  name          = local.codebuild_name
  description   = "Deploy an EC2 in the target account using terraform."
  build_timeout = 5
  service_role  = aws_iam_role.cb.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
  }

}
