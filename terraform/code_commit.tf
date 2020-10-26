resource "aws_codecommit_repository" "repo" {
  repository_name = "${var.application}-Golden-AMI-Builder"
  description     = "Golden AMI Pipeline for ${var.application}"
}

