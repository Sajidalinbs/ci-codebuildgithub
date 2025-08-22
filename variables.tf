variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "github_organization" {
  description = "GitHub organization or username"
  type        = string
  default     = "Sajidalinbs"
}

variable "app_secret_token" {
  description = "GitHub Personal Access Token for CodeBuild authentication. Must have 'repo' and 'admin:repo_hook' scopes."
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.app_secret_token) > 0
    error_message = "GitHub token is required for webhook creation."
  }
  validation {
    condition     = can(regex("^ghp_[a-zA-Z0-9]{36}$", var.app_secret_token))
    error_message = "GitHub token must be a valid Personal Access Token starting with 'ghp_' and 40 characters long."
  }
}


variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "wiiv_pulse_AdminPortal"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.project_name))
    error_message = "Project name must contain only letters, numbers, hyphens, and underscores."
  }
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"
  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE"], var.codebuild_compute_type)
    error_message = "CodeBuild compute type must be one of: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "vpc_id" {
  description = "VPC ID for the resources"
  type        = string
  default     = "vpc-0f9667295b55dc69f"
}

variable "subnet_ids" {
  description = "Subnet IDs for CodeBuild"
  type        = list(string)
  default     = ["subnet-08bc4ce6a72c5171c", "subnet-01658883360cdf4c7"]
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for CodeBuild"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention must be between 1 and 3653 days."
  }
}

variable "build_notification_emails" {
  description = "List of email addresses to receive build notifications"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for email in var.build_notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "All email addresses must be valid email format."
  }
}



