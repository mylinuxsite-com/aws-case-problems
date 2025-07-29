resource "aws_s3_bucket" "this" {
  for_each = toset([var.cicd_bucket_suffix, var.tfstate_bucket_suffix])

  bucket = lower("${var.pipeline_name}-${each.value}")
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = toset([var.cicd_bucket_suffix, var.tfstate_bucket_suffix])

  bucket = aws_s3_bucket.this[each.value].id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:sts::${var.target_account}:assumed-role/${var.target_account_role}/${var.target_account_role_session}"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.this[var.tfstate_bucket_suffix].arn,
      "${aws_s3_bucket.this[var.tfstate_bucket_suffix].arn}/${var.tfstate_file_name}"
    ]
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = local.tfstate_bucket_name
  policy = data.aws_iam_policy_document.this.json
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.input_artifacts_dir
  output_path = "${path.module}/.workdir/${var.input_artifact}"
  excludes = [
    "terraform/.terraform*",
    "terraform/terraform.tfstate*",
  ]

}

resource "aws_s3_object" "this" {
  bucket = local.cicd_bucket_name
  key    = var.input_artifact
  source = "${path.module}/.workdir/${var.input_artifact}"

  etag = data.archive_file.this.output_md5

  provisioner "local-exec" {
    when        = destroy
    working_dir = "${path.module}/.workdir"
    command     = "rm *.zip"
  }
}