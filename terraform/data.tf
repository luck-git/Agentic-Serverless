data "aws_ssm_parameter" "github_owner" {
  name = "/github_owner"
}

data "aws_ssm_parameter" "github_repo" {
  name = "/github_repo"
}

data "aws_ssm_parameter" "github_token" {
  name            = "/github_token"
  with_decryption = true
}

data "aws_ssm_parameter" "github_branch" {
  name = "/github_branch"
}