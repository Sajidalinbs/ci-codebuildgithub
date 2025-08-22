# Multi-Repo CI/CD Infrastructure with Terraform

This Terraform configuration creates a complete CI/CD infrastructure for multiple repositories with different tech stacks (React, Node.js, Java, Python) using AWS CodeBuild and ECR.

## 🚨 **Why Terraform Instead of Just buildspec.yml?**

The `buildspec.yml` file alone is **NOT sufficient** because:

1. **buildspec.yml is just build instructions** - it tells CodeBuild WHAT to do
2. **You need the infrastructure first** - ECR repositories, CodeBuild projects, IAM roles, etc.
3. **Without infrastructure, buildspec will fail** with "repository not found" or "access denied" errors

## 🏗️ **What This Terraform Configuration Creates**

### **Infrastructure Components:**
- **ECR Repositories**: One for each application with lifecycle policies
- **CodeBuild Projects**: Automated build projects for each repo
- **IAM Roles & Policies**: Secure access control
- **S3 Bucket**: Artifact storage and build logs
- **CloudWatch Logs**: Build monitoring and debugging
- **Security Groups**: Network security (if VPC is specified)

### **Multi-Stack Support:**
- **React Applications**: Frontend builds with npm
- **Node.js APIs**: Backend services with npm
- **Java Services**: Spring Boot applications with Maven
- **Python Apps**: Python applications with pip

## 📁 **Project Structure**

```
terraform/
├── main.tf              # Main configuration and providers
├── variables.tf         # Input variables
├── ecr.tf              # ECR repositories and policies
├── iam.tf              # IAM roles and policies
├── codebuild.tf        # CodeBuild projects
├── outputs.tf          # Output values
├── deploy.sh           # Deployment script
└── README.md           # This file

buildspecs/
├── buildspec-react.yml    # React build instructions
├── buildspec-node.yml     # Node.js build instructions
├── buildspec-java.yml     # Java build instructions
└── buildspec-python.yml   # Python build instructions
```

## 🛠️ **Prerequisites**

- **Terraform** (>= 1.0)
- **AWS CLI** configured with appropriate permissions
- **jq** for JSON processing
- **Docker** (for local testing)

## 🚀 **Quick Deployment**

### **1. Clone and Navigate**
```bash
cd terraform
```

### **2. Deploy Infrastructure**
```bash
chmod +x deploy.sh
./deploy.sh
```

### **3. Customize Configuration**
```bash
./deploy.sh --environment staging --region us-west-2 --project my-project
```

## 🔧 **Configuration Options**

### **Environment Variables**
```bash
export TF_VAR_project_name="my-project"
export TF_VAR_environment="prod"
export TF_VAR_aws_region="us-west-2"
```

### **Repository Configuration**
Edit `terraform.tfvars` or modify the `repositories` variable in `variables.tf`:

```hcl
repositories = [
  {
    name        = "my-react-app"
    description = "My React Application"
    stack       = "react"
    build_image = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    buildspec   = "buildspecs/buildspec-react.yml"
  }
]
```

## 🎯 **Multi-Repo Architecture**

### **One Infrastructure, Multiple Repositories**
```
┌─────────────────────────────────────────────────────────────┐
│                    Shared Infrastructure                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   ECR Repo  │  │   ECR Repo  │  │   ECR Repo  │        │
│  │  (react-app)│  │  (node-api) │  │(java-service)│        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ CodeBuild   │  │ CodeBuild   │  │ CodeBuild   │        │
│  │ (react-app) │  │ (node-api)  │  │(java-service)│        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│              Shared IAM Roles & S3 Bucket                 │
└─────────────────────────────────────────────────────────────┘
```

### **Benefits:**
✅ **Cost Effective**: Shared resources across all repos  
✅ **Consistent**: Same security, monitoring, and policies  
✅ **Scalable**: Easy to add new repositories  
✅ **Maintainable**: Single source of truth for infrastructure  

## 🔄 **Dynamic Tagging System**

Every build automatically creates multiple tags:

- **Commit Hash**: `a1b2c3d` (from git)
- **Latest**: `latest` (always current)
- **Timestamp**: `20241201-143022` (build time)
- **Branch**: `main`, `develop`, `feature/*` (git branch)
- **Commit**: `commit-a1b2c3d` (explicit commit tag)

## 📊 **Repository Setup by Tech Stack**

### **React Applications**
1. Copy `buildspecs/buildspec-react.yml` to your repo root
2. Ensure you have a `Dockerfile` for containerization
3. Push code to trigger automatic builds

### **Node.js APIs**
1. Copy `buildspecs/buildspec-node.yml` to your repo root
2. Ensure you have a `Dockerfile` and `package.json`
3. Push code to trigger automatic builds

### **Java Services**
1. Copy `buildspecs/buildspec-java.yml` to your repo root
2. Ensure you have a `Dockerfile` and `pom.xml`
3. Push code to trigger automatic builds

### **Python Applications**
1. Copy `buildspecs/buildspec-python.yml` to your repo root
2. Ensure you have a `Dockerfile` and `requirements.txt`
3. Push code to trigger automatic builds

## 🔐 **Security Features**

- **IAM Least Privilege**: Minimal required permissions
- **ECR Encryption**: AES256 encryption at rest
- **Image Scanning**: Automatic vulnerability scanning
- **Private Repositories**: No public access
- **VPC Support**: Optional network isolation

## 📈 **Monitoring & Logging**

- **CloudWatch Logs**: Build process logs
- **S3 Logs**: Build artifacts and logs
- **Build History**: Track all builds across repos
- **Metrics**: Build success/failure rates

## 🚨 **Troubleshooting**

### **Common Issues**

1. **"Repository not found"**
   - Ensure ECR repository exists (check Terraform outputs)
   - Verify repository name matches exactly

2. **"Access denied"**
   - Check IAM permissions
   - Verify CodeBuild service role has ECR access

3. **"Build fails"**
   - Check buildspec file syntax
   - Verify Dockerfile exists and is correct
   - Review CloudWatch logs

### **Debug Commands**

```bash
# Check ECR repositories
aws ecr describe-repositories --region us-east-1

# Check CodeBuild projects
aws codebuild list-projects --region us-east-1

# View build logs
aws codebuild batch-get-builds --ids <build-id> --region us-east-1

# Check IAM roles
aws iam get-role --role-name <role-name>
```

## 🔄 **Adding New Repositories**

### **1. Update Terraform Configuration**
```hcl
repositories = [
  # ... existing repos ...
  {
    name        = "new-service"
    description = "New Microservice"
    stack       = "go"  # or any tech stack
    build_image = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    buildspec   = "buildspecs/buildspec-go.yml"
  }
]
```

### **2. Create Buildspec File**
Copy and customize the appropriate buildspec file for your tech stack.

### **3. Redeploy Infrastructure**
```bash
terraform plan
terraform apply
```

## 💰 **Cost Optimization**

- **ECR Lifecycle Policies**: Automatic cleanup of old images
- **S3 Lifecycle**: Automatic cleanup of old artifacts
- **CloudWatch Log Retention**: Configurable log retention
- **Shared Resources**: Cost sharing across repositories

## 📚 **Additional Resources**

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CodeBuild User Guide](https://docs.aws.amazon.com/codebuild/)
- [Amazon ECR User Guide](https://docs.aws.amazon.com/ecr/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License.

---

**Happy Infrastructure as Code! 🚀**
