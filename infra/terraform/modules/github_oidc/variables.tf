variable "project" { type = string }
variable "env"     { type = string }

variable "github_owner" { type = string }
variable "github_repo"  { type = string }

variable "ecr_repo_arn" { type = string }

variable "codedeploy_app_name" { type = string }
variable "codedeploy_deployment_group" { type = string }

variable "region" {
  type    = string
  default = "us-east-1"
}
