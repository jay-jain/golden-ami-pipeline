resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.application}-golden-ami-pipeline-artifacts-xquj"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_role" "service_role" {
  name = "${var.application}-Golden-AMI-Builder-Service-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "service_role_policy" {
  role = aws_iam_role.service_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.artifact_bucket.arn}",
        "${aws_s3_bucket.artifact_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.service_role.name
  policy_arn = "arn:${var.arn_format}:iam::aws:policy/PowerUserAccess"
}

resource "aws_codebuild_project" "example" {
  name         = "${var.application}Golden-AMI-Build"
  description  = "Builds Golden AMI for ${var.application}"
  service_role = aws_iam_role.service_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = var.codebuild_environment
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "BUILD_OUTPUT_BUCKET"
      value = aws_s3_bucket.artifact_bucket.id
    }

    environment_variable {
      name  = "BUILD_VPC_ID"
      value = var.vpc_id
    }

    environment_variable {
      name  = "BUILD_SUBNET_ID"
      value = var.subnet_id
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  source_version = "master"
}