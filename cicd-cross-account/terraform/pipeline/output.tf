output "cicd_bucket_name" {
  value = aws_s3_bucket.this[var.cicd_bucket_suffix].id
}

output "tfstate_bucket_name" {
  value = aws_s3_bucket.this[var.tfstate_bucket_suffix].id
}

output "codebuild_name" {
  value = local.codebuild_name
}

output "codepipeline_name" {
  value = local.codepipeline_name
}
