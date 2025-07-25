# CodeBuild IAM Role
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-codebuild-role"
  })
}

# CodeBuild IAM Policy - Basic Permissions
resource "aws_iam_role_policy" "codebuild_basic_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-basic-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketEncryption",
          "s3:PutBucketEncryption",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging"
        ]
        Resource = [
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
          aws_s3_bucket.codepipeline_artifacts.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.codepipeline_artifacts.arn
      }
    ]
  })
}

# CodeBuild IAM Policy - Terraform Permissions
resource "aws_iam_role_policy" "codebuild_terraform_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-terraform-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # API Gateway permissions
          "apigateway:*",
          
          # DynamoDB permissions
          "dynamodb:*",
          
          # IAM permissions
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          
          # Lambda permissions
          "lambda:*",
          
          # SQS permissions
          "sqs:*",
          
          # Step Functions permissions
          "states:*",
          
          # CloudWatch permissions
          "cloudwatch:*",
          "logs:*",
          
          # CodeBuild permissions - THIS WAS MISSING
          "codebuild:BatchGetProjects",
          "codebuild:CreateProject",
          "codebuild:UpdateProject",
          "codebuild:DeleteProject",
          "codebuild:ListProjects",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          
          # CodePipeline permissions - THESE WERE MISSING
          "codepipeline:CreatePipeline",
          "codepipeline:UpdatePipeline",
          "codepipeline:DeletePipeline",
          "codepipeline:GetPipeline",
          "codepipeline:GetPipelineState",
          "codepipeline:ListPipelines",
          "codepipeline:StartPipelineExecution",
          "codepipeline:StopPipelineExecution",
          "codepipeline:GetPipelineExecution",
          "codepipeline:ListPipelineExecutions",
          "codepipeline:PutWebhook",
          "codepipeline:DeleteWebhook",
          "codepipeline:RegisterWebhookWithThirdParty",
          "codepipeline:DeregisterWebhookWithThirdParty",
          "codepipeline:ListWebhooks",
          
          # S3 permissions for state backend and general bucket operations
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          
          # SNS permissions
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:TagResource",
          "sns:UntagResource",
          
          # Additional permissions
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild SSM Access Policy - FIXED THE PARAMETER NAMES
resource "aws_iam_role_policy" "codebuild_ssm_access" {
  name = "${var.project_name}-${var.environment}-codebuild-ssm-access"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/github_token",
          "arn:aws:ssm:*:*:parameter/github_owner",
          "arn:aws:ssm:*:*:parameter/github_repo",
          "arn:aws:ssm:*:*:parameter/github_branch"
        ]
      }
    ]
  })
}

# CodePipeline IAM Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-codepipeline-role"
  })
}

# CodePipeline IAM Policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.environment}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.terraform_build.arn
      }
    ]
  })
}