
resource "aws_iam_role" "this" {
  name = var.account_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
            AWS = "arn:aws:iam::${var.cicd_account}:role/${var.pipeline_name}-CodeBuildServiceRole"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "tfstates3bucket"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${local.tfstate_bucket_name}",
      "arn:aws:s3:::${local.tfstate_bucket_name}/${var.tfstate_file_name}"
    ]
  }

  statement {
    sid = "ec2"
    actions = [
      "ec2:*"
    ]

    resources = ["*"]
  }

  statement {
    sid = "iam"
    actions = [
      "iam:CreatePolicy",
      "iam:ListPolicies",
      "iam:CreateInstanceProfile",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:CreateRole",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListInstanceProfiles",
      "iam:DeleteRole",
      "iam:DeleteInstanceProfile",
      "iam:DeletePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:PassRole",
      "iam:DetachRolePolicy"
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "cp" {
  name = "${var.account_role}-policy"
  role = aws_iam_role.this.id

  policy = data.aws_iam_policy_document.this.json
}