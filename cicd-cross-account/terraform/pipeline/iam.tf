resource "aws_iam_role" "cb" {
  name = "${var.pipeline_name}-CodeBuildServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "cb" {
  statement {
    sid = "cicds3bucket"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "arn:aws:s3:::${local.cicd_bucket_name}",
      "arn:aws:s3:::${local.cicd_bucket_name}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"

      values = [local.account]
    }
  }

  statement {
    sid = "tfs3bucket"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${local.tfstate_bucket_name}",
      "arn:aws:s3:::${local.tfstate_bucket_name}/*"
    ]
  }

  statement {
    sid = "loggroup"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${local.region}:${local.account}:log-group:/aws/codebuild/${local.codebuild_name}",
      "arn:aws:logs:${local.region}:${local.account}:log-group:/aws/codebuild/${local.codebuild_name}:*"
    ]
  }

  statement {
    sid = "codebuild"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]

    resources = [
      "arn:aws:codebuild:${local.region}:${local.account}:report-group/${local.codebuild_name}-*"
    ]
  }

  statement {
    sid = "assumerole"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.target_account}:role/${var.target_account_role}"
    ]
  }
}

resource "aws_iam_role_policy" "cb" {
  name = "${var.pipeline_name}-CodeBuildPolicy"
  role = aws_iam_role.cb.id

  policy = data.aws_iam_policy_document.cb.json
}


#CodePipeline IAMs
resource "aws_iam_role" "cp" {
  name = "${var.pipeline_name}-CodePipelineServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "cp" {
  statement {
    sid = "cicds3bucket"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "arn:aws:s3:::${local.cicd_bucket_name}",
      "arn:aws:s3:::${local.cicd_bucket_name}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"

      values = [local.account]
    }
  }

  statement {
    sid = "codebuild"
    actions = [
      "codebuild:ListBuilds",
      "codebuild:ListProjects",
      "codebuild:StopBuild",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]

    resources = [
      aws_codebuild_project.this.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"

      values = [local.account]
    }
  }

}

resource "aws_iam_role_policy" "cp" {
  name = "${var.pipeline_name}-CodePipelinePolicy"
  role = aws_iam_role.cp.id

  policy = data.aws_iam_policy_document.cp.json
}
