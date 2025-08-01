# DoFS Project - Order Fulfillment System

## Overview

This project implements a fully automated order processing system on AWS, leveraging serverless and managed services. It includes REST API ingestion, workflow orchestration, and fulfillment processing with retries and DLQ handling, all managed and deployed using Terraform with a CI/CD pipeline.

### Key Components

- **API Gateway + API Handler Lambda** accepting orders via POST `/order`
- **AWS Step Functions** orchestrating validation, storage, and queuing
- **DynamoDB tables** for storing valid and failed orders
- **SQS queue & dead-letter queue (DLQ)** for order fulfillment messages
- **Fulfillment Lambda** processing orders asynchronously with success/failure simulation
- **AWS CodePipeline and CodeBuild** for automated Terraform provisioning and deployments

## Architecture Diagram

![Architecture Diagram] https://drive.google.com/file/d/1XLN3pjKdbMDSwKxB6Il8p1IzFWyR25Ev/view?usp=sharing

*The architecture diagram shows the complete flow from API Gateway through Step Function orchestration, DynamoDB interactions, SQS queues, Fulfillment Lambda, and the DLQ mechanism.*

## Step Functions Workflow

![Step Functions Graph] https://drive.google.com/file/d/1fGZ8DkGVxGwUhvuFpl-GKHtsAKWtZEfV/view?usp=sharing

*The Step Functions workflow graph illustrates the order processing flow including validation, storage, and queue integration steps.*

## System Components

### 1. API Gateway + API Handler Lambda
- Exposes REST endpoint `/order`
- Triggers Step Function execution for each order request
- Handles authentication and request validation

### 2. Step Function Orchestrator
- **Validate Lambda**: Validates incoming orders
- **Store Lambda**: Stores orders in DynamoDB `orders` table
- **Queue Integration**: Pushes orders into SQS `order_queue` for fulfillment processing

### 3. Fulfillment Lambda
- Invoked by SQS messages in `order_queue`
- Simulates processing with a ~70% success rate
- Updates order status in DynamoDB as `FULFILLED` or `FAILED`
- Failed orders are retried; after max retries sent to DLQ (`order_dlq`)

### 4. Dead Letter Queue Handling
- Failed messages after retries sent to `order_dlq`
- Lambda processes messages from DLQ to `failed_orders` DynamoDB table
- Optional SNS alert triggers if DLQ depth exceeds threshold for monitoring

### 5. DynamoDB Tables
- **orders table**: Primary key `order_id`, stores all order records
- **failed_orders table**: Collects dead-lettered order messages for analysis

### 6. CI/CD Pipeline
- Terraform-defined CodePipeline with stages for source, build, and deploy
- CodeBuild runs Terraform plan and apply with secrets fetched securely via SSM Parameter Store
- Optional manual approval before deploying to development environment
- Remote Terraform state stored in S3 backend

## Folder Structure

```
dofs-project/
├── lambdas/
│   ├── api_handler/                  # API Gateway lambda function
│   ├── validator/                    # Validation lambda
│   ├── order_storage/                # Store order lambda
│   └── fulfill_order/                # Fulfillment lambda
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf                    # S3 backend config
│   ├── modules/
│   │   ├── api-gateway/
│   │   ├── lambdas/
│   │   ├── dynamodb/
│   │   ├── sqs/
│   │   ├── step-functions/
│   │   └── monitoring/
│   └── cicd/
│       ├── codebuild.tf
│       ├── codepipeline.tf
│       └── iam_roles.tf
├── buildspec.yml                     # CodeBuild specification file
├── .github/
│   └── workflows/
│       └── ci.yml                   # Optional GitHub Actions workflow
├── README.md
└── docs/
    ├── architecture-diagram.png     # Architecture diagram image
    └── step-functions-graph.png     # Step Functions workflow graph
```

## Prerequisites

- AWS CLI configured with credentials and permissions to create/update all used AWS resources
- Terraform installed locally or used via the pipeline
- AWS SSM Parameter Store configured with secret parameters (`github_token`, `github_owner`, `github_repo`, `github_branch`)
- GitHub repository access with appropriate permissions and token securely stored in Parameter Store

## Setup Instructions

### 1. Clone Repository
```bash
git clone https://github.com/luck-git/Agentic-Serverless.git
cd dofs-project
```

### 2. Configure AWS Environment
Configure AWS credentials and environment variables or use the pipeline with the pre-configured AWS CodeBuild role.

### 3. Deploy Infrastructure

**Option A: Local Terraform Deployment**
```bash
terraform init
terraform plan 
terraform apply 
```

**Option B: CI/CD Pipeline Deployment**
1. Commit code changes to trigger CodePipeline
2. CodeBuild will fetch parameters securely and run Terraform to deploy/update infrastructure
3. Manual approval stage (if enabled) will pause for validation before deploying

## Testing Guide

### Success Scenario

1. Post an order to the API Gateway endpoint:
```bash
curl -X POST https://lt2bq3ch28.execute-api.ap-southeast-2.amazonaws.com/prod/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "order123",
    "product": "Widget",
    "quantity": 2,
    "price": 49.99
}'
```

2. Verify the Step Function execution succeeds in AWS Console
3. Confirm order is stored in DynamoDB `orders` table with status `PENDING`
4. Observe Fulfillment Lambda processes the order and updates status to `FULFILLED`

### Failure and DLQ Handling

1. Simulate fulfillment failures by adjusting success rate or causing failures
2. Check that messages are retried via SQS
3. Confirm messages exceeding retry limit land in SQS DLQ (`order_dlq`)
4. Verify failed messages are persisted in `failed_orders` DynamoDB table
5. Optional: Observe SNS alert notifications on DLQ depth threshold breach

## CI/CD Pipeline Explanation

- **Source Stage**: Monitors GitHub/CodeCommit repository for changes
- **Build Stage**: Runs Terraform plan and apply with variables dynamically injected from AWS Parameter Store
- **Manual Approval**: (Optional) Allows operators to verify changes before applying to DEV environment
- **Deploy Stage**: Creates or updates AWS services and infrastructure per Terraform configs
- **Backend**: Terraform remote state stored securely in an S3 bucket
- **IAM Roles**: Properly scoped roles for CodePipeline, CodeBuild, Lambda, and other services with least privilege

## Troubleshooting

- Check IAM permissions if access denied errors occur for SSM or Terraform operations
- Verify `terraform.tfvars` variables are properly injected in the build environment
- Monitor Step Function executions and logs for debugging errors or validation failures
- Inspect SQS DLQ for unprocessed or failed orders
- Confirm Lambda logs in CloudWatch to investigate processing issues
- Validate CodePipeline stages for errors or failures in builds

## Resources

- **GitHub Repository**: [https://github.com/luck-git/Agentic-Serverless](https://github.com/luck-git/Agentic-Serverless)
- **Demo Video**: [Demo Video on Loom](https://www.loom.com/share/your-video-id)

## Next Steps

To complete the documentation setup:

1. **Add your architecture diagram**: Save your architecture diagram as `docs/architecture-diagram.png`
2. **Add Step Functions graph**: Download your Step Functions graph and save as `docs/step-functions-graph.png`  
3. **Update the demo video link**: Replace the placeholder Loom link with your actual video URL
4. **Verify all endpoints**: Update the API Gateway endpoint URL if it has changed

The README now properly references both diagrams and provides a cleaner, more professional structure for your project documentation.