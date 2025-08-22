# ECR Repository Information
output "ecr_repository" {
  description = "ECR repository information"
  value = {
    name     = aws_ecr_repository.react_app.name
    arn      = aws_ecr_repository.react_app.arn
    registry = aws_ecr_repository.react_app.registry_id
    url      = aws_ecr_repository.react_app.repository_url
    stack    = "react"
  }
}

# CodeBuild Project Information
output "codebuild_project" {
  description = "CodeBuild project information"
  value = {
    name        = aws_codebuild_project.react_app_build.name
    arn         = aws_codebuild_project.react_app_build.arn
    description = aws_codebuild_project.react_app_build.description
    stack       = "react"
    webhook_url = aws_codebuild_webhook.react_app_webhook.url
  }
}

# IAM Role Information
output "codebuild_service_role" {
  description = "CodeBuild service role ARN"
  value       = aws_iam_role.codebuild_service_role.arn
}

# S3 Bucket Information
output "codebuild_artifacts_bucket" {
  description = "CodeBuild artifacts S3 bucket"
  value = {
    name = aws_s3_bucket.codebuild_artifacts.bucket
    arn  = aws_s3_bucket.codebuild_artifacts.arn
  }
}

# CloudWatch Log Group
output "cloudwatch_log_group" {
  description = "CloudWatch log group for CodeBuild"
  value = {
    name = aws_cloudwatch_log_group.codebuild_log_group.name
    arn  = aws_cloudwatch_log_group.codebuild_log_group.arn
  }
}

# Security Group (if VPC is used)
output "codebuild_security_group" {
  description = "CodeBuild security group"
  value = var.vpc_id != "" ? {
    id   = aws_security_group.codebuild_sg[0].id
    name = aws_security_group.codebuild_sg[0].name
  } : null
}

# Secrets Manager Information
output "github_token_secret" {
  description = "GitHub token stored in Secrets Manager"
  value = {
    secret_name = aws_secretsmanager_secret.github_token.name
    secret_arn  = aws_secretsmanager_secret.github_token.arn
    version_id  = aws_secretsmanager_secret_version.github_token.version_id
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Quick start commands for developers"
  value = {
    login_to_ecr = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    build_example = "docker build -t ${var.project_name} . && docker tag ${var.project_name}:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}:latest"
    push_example = "docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}:latest"
  }
}
