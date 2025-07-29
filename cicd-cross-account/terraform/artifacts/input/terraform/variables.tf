variable "region" {
  type        = string
  default     = "us-east-1"
  description = "The region where the resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "The tags that will be applied to all the resources."
  default = {
    "CaseName" = "CodePipeline-Cross-Account"
  }
}

variable "ami_name" {
  type        = string
  description = "The ami to use."
  default     = "al2023-ami-2023.8.20250715.0-kernel-6.1-x86_64"
}

variable "ec2_name" {
  type        = string
  description = "The EC2 name."
  default     = "codepipeline-x-accounts"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
  default     = "t2.micro"
}

variable "subnet_id" {
  type        = string
  description = "The EC2 subnet id"
}

variable "security_group" {
  type        = string
  description = "The EC2 security group."
}


