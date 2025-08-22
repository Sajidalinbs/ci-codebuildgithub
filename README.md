# AWS CI/CD Infrastructure with Terraform

This Terraform configuration creates a complete CI/CD infrastructure for applications using AWS CodeBuild, ECR, and GitHub integration. The infrastructure is designed to be reusable across different projects with project-specific variable files.

## 🏗️ **Infrastructure Components & Functionality**

### **1. ECR (Elastic Container Registry) Repository**
- **Purpose**: Stores Docker container images for your application
- **Features**:
  - Automatic image scanning for vulnerabilities
  - AES256 encryption at rest
  - Lifecycle policies for automatic cleanup of old images
  - Keeps last 5 'latest' tagged images, 10 versioned images, and 20 commit-based images
  - Expires untagged images older than 1 day

### **2. CodeBuild Project**
- **Purpose**: Automatically builds, tests, and deploys your application
- **Features**:
  - GitHub source integration with webhook triggers
  - Triggers on push to `main` and `develop` branches
  - Triggers on pull request creation from `feature/*` branches
  - Uses Amazon Linux 2 build environment with Docker support
  - Configurable compute resources (SMALL/MEDIUM/LARGE)
  - Local caching for faster builds
  - Build timeout of 60 minutes

### **3. IAM Roles & Policies**
- **Purpose**: Secure access control for AWS services
- **Components**:
  - **CodeBuild Service Role**: Allows CodeBuild to access ECR, S3, CloudWatch, and VPC resources
  - **ECR Power User Policy**: Full ECR access for building and pushing images
  - **CloudWatch Logs Policy**: Logging and monitoring capabilities
  - **S3 Access**: Read/write access to artifacts bucket
  - **VPC Access**: Network interface management for VPC deployments

### **4. S3 Bucket for Artifacts**
- **Purpose**: Stores build artifacts, logs, and build outputs
- **Features**:
  - Versioning enabled for artifact tracking
  - Server-side encryption (AES256)
  - Public access blocked for security
  - Lifecycle policy: artifacts expire after 90 days, non-current versions after 30 days

### **5. CloudWatch Logs**
- **Purpose**: Centralized logging and monitoring for build processes
- **Features**:
  - Configurable log retention (default: 30 days)
  - Structured logging for easy debugging
  - Integration with AWS monitoring services

### **6. Security Groups**
- **Purpose**: Network security for VPC deployments
- **Features**:
  - Egress-only rules (allows outbound traffic)
  - VPC-specific deployment support
  - Configurable through variables

### **7. GitHub Integration**
- **Purpose**: Automated build triggers from GitHub events
- **Features**:
  - Personal Access Token stored securely in AWS Secrets Manager
  - Webhook triggers for push and pull request events
  - Support for multiple branch patterns
  - Automatic credential management

### **8. Build Notifications (SNS + CloudWatch Events)**
- **Purpose**: Real-time email notifications for build status changes
- **Features**:
  - **CloudWatch Events**: Automatically captures CodeBuild state changes
  - **SNS Topic**: Distributes notifications to subscribed email addresses
  - **Structured JSON Messages**: Clean, parseable notification format
  - **Real-time Alerts**: Immediate notifications for build success, failure, and status changes
  - **Configurable Recipients**: Add/remove email addresses through variables
  - **Build Details**: Includes project name, build status, timestamp, region, and build ID
  - **Automatic Filtering**: Only captures events for your specific project

**Notification Message Format**:
```json
{
  "message": "CodeBuild: project-name - Status: SUCCEEDED at 2025-08-22T16:55:42Z (us-east-1)",
  "build_id": "arn:aws:codebuild:us-east-1:account:build/project-name:build-id",
  "project_name": "project-name",
  "build_status": "SUCCEEDED",
  "timestamp": "2025-08-22T16:55:42Z",
  "region": "us-east-1"
}
```

## 🔄 **Reusability for Different Projects**

This infrastructure can be easily reused for different projects by using project-specific variable files. Each application gets its own configuration file with appropriate settings.

### **Available Applications**

#### **1. Pulse Admin UI** (`terraform.tfvars.pulse-admin-ui`)
- **Project Name**: `pulse-admin-ui`
- **Compute Type**: `BUILD_GENERAL1_MEDIUM`
- **Use Case**: Admin dashboard and management interface
- **Resource Requirements**: Medium (balanced performance and cost)

#### **2. Pulse Promoter UI** (`terraform.tfvars.pulse-promoter-ui`)
- **Project Name**: `pulse-promoter-ui`
- **Compute Type**: `BUILD_GENERAL1_SMALL`
- **Use Case**: Promoter-facing user interface
- **Resource Requirements**: Small (lightweight builds, cost-effective)

#### **3. Pulse Backend** (`terraform.tfvars.pulse-backend`)
- **Project Name**: `pulse-backend`
- **Compute Type**: `BUILD_GENERAL1_LARGE`
- **Use Case**: Backend API and services
- **Resource Requirements**: Large (heavy builds, maximum performance)

### **How to Use Project-Specific Variables**

1. **Deploy directly using the appropriate variable file**:
   ```bash
   # For Pulse Admin UI
   terraform init
   terraform plan -var-file="terraform.tfvars.pulse-admin-ui"
   terraform apply -var-file="terraform.tfvars.pulse-admin-ui"
   
   # For Pulse Promoter UI
   terraform init
   terraform plan -var-file="terraform.tfvars.pulse-promoter-ui"
   terraform apply -var-file="terraform.tfvars.pulse-promoter-ui"
   
   # For Pulse Backend
   terraform init
   terraform plan -var-file="terraform.tfvars.pulse-backend"
   terraform apply -var-file="terraform.tfvars.pulse-backend"
   ```

2. **Configure Build Notifications**:
   Each project-specific variable file includes a `build_notification_emails` list where you can specify email addresses to receive build notifications:
   ```hcl
   # Example from terraform.tfvars.pulse-admin-ui
   build_notification_emails = [
     "dev-team@company.com",
     "devops@company.com"
   ]
   ```
   
   **Notification Types**:
   - **Build Started**: `IN_PROGRESS` events
   - **Build Success**: `SUCCEEDED` events  
   - **Build Failure**: `FAILED` events
   - **Build Stopped**: `STOPPED` events

3. **Customize the configuration** if needed by overriding specific variables:
   ```bash
   # Example: Change environment for production
   terraform apply -var-file="terraform.tfvars.pulse-admin-ui" -var="environment=prod"
   
   # Example: Adjust compute type for specific needs
   terraform apply -var-file="terraform.tfvars.pulse-admin-ui" -var="codebuild_compute_type=BUILD_GENERAL1_LARGE"
   ```

4. **For different environments**, you can also create environment-specific variable files:
   ```bash
   # Create staging configuration
   cp terraform.tfvars.pulse-admin-ui terraform.tfvars.pulse-admin-ui.staging
   # Edit the staging file to change environment and other settings
   
   # Deploy to staging
   terraform apply -var-file="terraform.tfvars.pulse-admin-ui.staging"
   ```

## 🚀 **Deployment Steps**

### **Prerequisites**
1. **Install Required Tools**:
   ```bash
   # Install Terraform (>= 1.0)
   # Download from: https://www.terraform.io/downloads.html
   
   # Install AWS CLI
   # Download from: https://aws.amazon.com/cli/
   
   # Install jq (for JSON processing)
   # Windows: choco install jq
   # macOS: brew install jq
   # Linux: sudo apt-get install jq
   ```

2. **AWS Configuration**:
   ```bash
   # Configure AWS credentials
   aws configure
   
   # Or set environment variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **GitHub Token Setup**:
   - Create a GitHub Personal Access Token with `repo` and `admin:repo_hook` scopes
   - Token must start with `ghp_` and be 40 characters long
   - **⚠️ Security Note**: Never commit actual GitHub tokens to version control
   - Use the provided `terraform.tfvars.*` files as templates only
   - Create your own `terraform.tfvars` file with real values for deployment
   - **Variable Name**: Use `app_secret_token` in your variable files

### **Step 1: Clone and Navigate**
```bash
# Clone your repository
git clone <your-repo-url>
cd ci-codebuild-github

# Verify Terraform files
ls -la *.tf
ls -la terraform.tfvars.*
```

### **Step 2: Choose Application Configuration**
```bash
# For Pulse Admin UI (Medium compute)
terraform plan -var-file="terraform.tfvars.pulse-admin-ui"
terraform apply -var-file="terraform.tfvars.pulse-admin-ui"

# For Pulse Promoter UI (Small compute)
terraform plan -var-file="terraform.tfvars.pulse-promoter-ui"
terraform apply -var-file="terraform.tfvars.pulse-promoter-ui"

# For Pulse Backend (Large compute)
terraform plan -var-file="terraform.tfvars.pulse-backend"
terraform apply -var-file="terraform.tfvars.pulse-backend"

# Or create custom configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform plan
terraform apply
```

### **Step 3: Initialize Terraform**
```bash
# Initialize Terraform and download providers
terraform init

# Verify the configuration
terraform plan
```

### **Step 4: Deploy Infrastructure**
```bash
# Deploy the infrastructure
terraform apply

# Review the plan and type 'yes' to confirm
```

### **Step 5: Verify Deployment**
```bash
# Check the outputs
terraform output

# Verify build notifications are configured
terraform output build_notifications

# Verify ECR repository
aws ecr describe-repositories --repository-names your-project-name

# Verify CodeBuild project
aws codebuild list-projects --region us-east-1

# Check GitHub webhook
aws codebuild list-webhooks --project-name your-project-name-dev-build
```

### **Step 6: Test the Pipeline**
1. **Push code to your GitHub repository**:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```

2. **Monitor the build**:
   - Check AWS CodeBuild console
   - View CloudWatch logs
   - Monitor ECR for new images

## 🔧 **Configuration Options**

### **Environment-Specific Deployments**
```bash
# Development environment
terraform apply -var="environment=dev"

# Staging environment
terraform apply -var="environment=staging"

# Production environment
terraform apply -var="environment=prod"
```

### **Custom Build Specifications**
The infrastructure expects a `buildspec.yml` file in your repository root.

## 📊 **Monitoring & Troubleshooting**

### **CloudWatch Logs**
```bash
# View build logs
aws logs describe-log-streams --log-group-name "/aws/codebuild/your-project-name-dev"

# Get specific log events
aws logs get-log-events --log-group-name "/aws/codebuild/your-project-name-dev" --log-stream-name "build-log"
```

### **Build Notifications**
```bash
# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic --topic-arn "arn:aws:sns:region:account:topic-name"

# Verify CloudWatch Events rule
aws events describe-rule --name "your-project-name-dev-build-state-change"

# Test SNS topic (sends test message)
aws sns publish --topic-arn "arn:aws:sns:region:account:topic-name" --message "Test notification"
```

### **CodeBuild Status**
```bash
# List recent builds
aws codebuild list-builds --project-name your-project-name-dev-build

# Get build details
aws codebuild batch-get-builds --ids build-id-here
```

### **ECR Operations**
```bash
# List images in repository
aws ecr list-images --repository-name your-project-name

# Describe repository
aws ecr describe-repositories --repository-names your-project-name
```

## 🔒 **Security Best Practices**

### **GitHub Token Security**
- **Never commit real tokens**: The `terraform.tfvars.*` files contain placeholder values only
- **Use environment variables**: Set `TF_VAR_github_token` environment variable for production
- **Rotate tokens regularly**: GitHub tokens should be rotated every 90 days
- **Minimal permissions**: Only grant the minimum required scopes (`repo` and `admin:repo_hook`)

### **AWS Security**
- **Use IAM roles**: Prefer IAM roles over access keys when possible
- **Principle of least privilege**: Grant only necessary permissions to CodeBuild and other services
- **Secrets management**: Store sensitive values in AWS Secrets Manager (already configured)
- **Network security**: Use VPC and security groups for production deployments

### **Repository Security**
- **Branch protection**: Enable branch protection rules on `main` and `develop` branches
- **Code review**: Require pull request reviews before merging
- **Secret scanning**: GitHub automatically scans for secrets (as you experienced)
- **Dependency scanning**: Regularly update Terraform providers and dependencies