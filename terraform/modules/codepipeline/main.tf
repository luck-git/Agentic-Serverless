# CodeBuild Project
resource "aws_codebuild_project" "terraform_build" {
  name          = "${var.project_name}-${var.environment}-terraform-build"
  description   = "Terraform build project for ${var.project_name}"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

   environment_variable {
      name  = "GITHUB_USER"
      value = "github_user"
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = "github_token"
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "GITHUB_branch"
      value = "github_branch"
      type  = "PARAMETER_STORE"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = var.tags
}

# CodePipeline with minimal artifact store
resource "aws_codepipeline" "terraform_pipeline" {
  name     = "${var.project_name}-${var.environment}-terraform-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  # Required minimal artifact store
  artifact_store {
    location = aws_s3_bucket.minimal_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "TerraformBuild"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.terraform_build.name
      }
    }
  }

  tags = var.tags
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}