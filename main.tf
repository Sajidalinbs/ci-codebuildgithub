terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  backend "s3" {
    # Configure your S3 backend for state management
    bucket = "state-file-bucket-wiiv-n-virginia"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CreatedAt   = timestamp()
  }
  
  # Generate unique names for resources
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # AWS-compliant project name (lowercase, no special characters except hyphens)
  aws_project_name = lower(replace(var.project_name, "/[^a-zA-Z0-9-]/", "-"))
  
  # GitHub-compliant project name (preserves original case for repository URLs)
  github_project_name = var.project_name
}
