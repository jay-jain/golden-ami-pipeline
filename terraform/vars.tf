variable "codebuild_environment" {
  default = "aws/codebuild/standard:4.0"
  description = "Docker image to use for Code Build"
}

variable "vpc_id" {
  description = "VPC ID for Code Build"
}

variable "subnet_id" {
  description = "Subnet ID for Code Build"
}

variable "account_id" {}

variable "application"{}

variable "base_ami"{
  description = "Starting AMI for Launch Template when deploying the ASG. "
}

variable "instance_type"{
  default = "t2.micro" 
}

variable "region" {}

variable "availability_zones"{
  type = list
  default = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d","us-east-1e","us-east-1f"]
}

variable "key_name"{
  description = "Name of a SSH private key"
}

variable "vpc_security_group_ids"{
  type = list
}

variable "arn_format"{
  default = "aws"
}