module "network" {
  source = "../../modules/network"

  project = "app-automatic-pipeline"
  env     = "dev"

  vpc_cidr = "10.10.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  # continua com 1 subnet pública (ALB)
  public_subnet_cidrs = [
    "10.10.10.0/24",
    "10.10.11.0/24" # criada, mas pouco usada
  ]

  # agora 2 privadas (RDS exige)
  private_subnet_cidrs = [
    "10.10.20.0/24", # ECS
    "10.10.21.0/24"  # RDS (AZ diferente)
  ]

  single_nat_gateway = false
}

module "security" {
  source = "../../modules/security"

  project = "app-automatic-pipeline"
  env     = "dev"

  vpc_id   = module.network.vpc_id
  app_port = 8080
}

# Route table privada (necessária pro endpoint S3)
data "aws_route_tables" "private" {
  vpc_id = module.network.vpc_id

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  project = "app-automatic-pipeline"
  env     = "dev"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  route_table_ids    = module.network.private_route_table_ids

  vpce_security_group_id = module.security.vpce_sg_id
}


module "ecr" {
  source = "../../modules/ecr"

  project    = "app-automatic-pipeline"
  env        = "dev"
  repo_name  = "app-automatic-pipeline-api"
  max_images = 2
}

module "rds" {
  source = "../../modules/rds"

  project = "app-automatic-pipeline"
  env     = "dev"

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.rds_sg_id

  db_name     = "ticketdb"
  db_username = "ticketuser"
}

module "s3" {
  source = "../../modules/s3"

  project     = "app-automatic-pipeline"
  env         = "dev"
  bucket_name = "app-automatic-pipeline-files"
}

module "sqs_payment_processing_queue" {
  source = "../../modules/sqs"

  project    = "app-automatic-pipeline"
  env        = "dev"
  queue_name = "payment-processing-queue"
}

module "sqs_payment_result_queue" {
  source = "../../modules/sqs"

  project    = "app-automatic-pipeline"
  env        = "dev"
  queue_name = "payment-result-queue"
}

module "alb" {
  source = "../../modules/alb"

  project = "app-automatic-pipeline"
  env     = "dev"

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  app_port              = 8080
}

module "ecs" {
  source = "../../modules/ecs"

  project = "app-automatic-pipeline"
  env     = "dev"

  region = "us-east-1"

  private_subnet_ids    = module.network.private_subnet_ids
  ecs_security_group_id = module.security.ecs_sg_id
  target_group_arn      = module.alb.blue_target_group_arn

  # placeholder (pipeline vai trocar depois)
  ecr_image = "${module.ecr.repository_url}:placeholder"

  db_secret_arn = module.rds.db_secret_arn
  db_host       = module.rds.db_endpoint
  db_name       = module.rds.db_name

  s3_bucket_name                   = module.s3.bucket_name
  sqs_payment_processing_queue_url = module.sqs_payment_processing_queue.queue_url
  sqs_payment_result_queue_url     = module.sqs_payment_result_queue.queue_url
}

module "codedeploy" {
  source = "../../modules/codedeploy_ecs"

  project = "app-automatic-pipeline"
  env     = "dev"

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  listener_arn  = module.alb.listener_arn
  blue_tg_name  = module.alb.blue_target_group_name
  green_tg_name = module.alb.green_target_group_name
}


module "github_oidc" {
  source = "../../modules/github_oidc"

  project = "app-automatic-pipeline"
  env     = "dev"
  region  = "us-east-1"

  github_owner = "kaikeventura"
  github_repo  = "app-automatic-pipeline"

  ecr_repo_arn = "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/${module.ecr.repository_name}"

  codedeploy_app_name         = module.codedeploy.codedeploy_app_name
  codedeploy_deployment_group = module.codedeploy.codedeploy_deployment_group
}

data "aws_caller_identity" "current" {}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "alb_sg_id" { value = module.security.alb_sg_id }
output "ecs_sg_id" { value = module.security.ecs_sg_id }
output "rds_sg_id" { value = module.security.rds_sg_id }

output "ecr_repo_url" {
  value = module.ecr.repository_url
}

output "ecr_repo_name" {
  value = module.ecr.repository_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "payment_processing_queue_url" {
  value = module.sqs_payment_processing_queue.queue_url
}

output "sqs_payment_result_queue_url" {
  value = module.sqs_payment_result_queue.queue_url
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  value = module.ecs.task_definition_arn
}

output "ecs_task_role_arn" {
  value = module.ecs.task_role_arn
}

output "ecs_task_execution_role_arn" {
  value = module.ecs.task_execution_role_arn
}

output "codedeploy_app_name" {
  value = module.codedeploy.codedeploy_app_name
}

output "codedeploy_deployment_group" {
  value = module.codedeploy.codedeploy_deployment_group
}

output "github_actions_role_arn" {
  value = module.github_oidc.github_role_arn
}