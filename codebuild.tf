# GitHub Token stored in AWS Secrets Manager
resource "aws_secretsmanager_secret" "github_token" {
  name        = "${local.aws_project_name}-${var.environment}-github-pat-${random_id.secret_suffix.hex}"
  description = "GitHub Personal Access Token for CodeBuild authentication"
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-github-pat"
  })
}

# Random suffix for secret name to avoid conflicts during recreation
resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.app_secret_token
  
  depends_on = [aws_secretsmanager_secret.github_token]
}

# GitHub Source Credentials for CodeBuild using Secrets Manager
resource "aws_codebuild_source_credential" "github_credentials" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = aws_secretsmanager_secret_version.github_token.secret_string
  
  depends_on = [aws_secretsmanager_secret_version.github_token]
}

# CodeBuild Project for React app
resource "aws_codebuild_project" "react_app_build" {
  name          = "${local.aws_project_name}-${var.environment}-build"
  description   = "Build project for React application"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "S3"
    location = aws_s3_bucket.codebuild_artifacts.bucket
    name     = "${var.project_name}-artifacts"
    packaging = "ZIP"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPOSITORY_NAME"
      value = var.project_name
    }

  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/${var.github_organization}/${local.github_project_name}.git"
    buildspec = "buildspec.yml"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE", "LOCAL_CUSTOM_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${local.aws_project_name}-${var.environment}"
      stream_name = "build-log"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_artifacts.id}/build-logs/${local.aws_project_name}"
    }
  }

  tags = merge(local.common_tags, {
    Name        = "${local.resource_prefix}-${var.project_name}-build"
    Stack       = "react"
    Repository  = var.project_name
    Description = "React Application"
  })
}

# Security Group for CodeBuild (if VPC is specified)
resource "aws_security_group" "codebuild_sg" {
  count = var.vpc_id != "" ? 1 : 0

  name        = "${local.aws_project_name}-${var.environment}-codebuild-sg"
  description = "Security group for CodeBuild project"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-codebuild-sg"
  })
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild_log_group" {
  name              = "/aws/codebuild/${local.aws_project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name       = "${local.resource_prefix}-${var.project_name}-logs"
    Repository = var.project_name
    Stack      = "react"
  })
}

# Time delay to ensure GitHub credentials are fully propagated
resource "time_sleep" "wait_for_credentials" {
  depends_on = [aws_codebuild_source_credential.github_credentials]
  create_duration = "30s"
}

# CodeBuild Webhook for GitHub
resource "aws_codebuild_webhook" "react_app_webhook" {
  project_name = aws_codebuild_project.react_app_build.name

  # Filter Group 1: Push to main branch
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"
    }
  }

  # Filter Group 2: Push to develop branch
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/develop"
    }
  }

  # Filter Group 3: Pull Request from feature branches
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/feature/*"
    }
  }

  depends_on = [time_sleep.wait_for_credentials]

  # Add lifecycle policy to handle temporary AWS service issues
  lifecycle {
    create_before_destroy = true
    # Retry on webhook creation failures
    ignore_changes = [project_name]
  }
}
