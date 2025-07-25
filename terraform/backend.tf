terraform {
  backend "s3" {
    bucket         = "agentic-serverless-tfstate-abhi-2025"
    key            = "order-app/terraform.tfstate"
    region         =  "ap-southeast-2"
    dynamodb_table = "terraform-lock"
  }
}