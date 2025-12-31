module "network" {
  source = "../../modules/network"

  project = var.project
  env     = var.env

  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  single_nat_gateway = false
}

module "security" {
  source = "../../modules/security"

  project = var.project
  env     = var.env

  vpc_id   = module.network.vpc_id
  app_port = var.app_port
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

  project = var.project
  env     = var.env

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  route_table_ids    = module.network.private_route_table_ids

  vpce_security_group_id = module.security.vpce_sg_id
}


module "ecr" {
  source = "../../modules/ecr"

  project    = var.project
  env        = var.env
  repo_name  = var.ecr_repo_name
  max_images = 2
}

# Novo repo para o Datadog Agent (Mirror)
module "ecr_datadog" {
  source = "../../modules/ecr"

  project    = var.project
  env        = var.env
  repo_name  = "datadog-agent"
  max_images = 1
}

module "rds" {
  source = "../../modules/rds"

  project = var.project
  env     = var.env

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.rds_sg_id

  db_name     = var.db_name
  db_username = var.db_username
}

module "s3" {
  source = "../../modules/s3"

  project     = var.project
  env         = var.env
  bucket_name = var.s3_bucket_name
}

module "sqs_payment_processing_queue" {
  source = "../../modules/sqs"

  project    = var.project
  env        = var.env
  queue_name = "payment-processing-queue"
}

module "sqs_payment_result_queue" {
  source = "../../modules/sqs"

  project    = var.project
  env        = var.env
  queue_name = "payment-result-queue"
}

module "domain" {
  source = "../../modules/domain"
  count  = var.enable_https ? 1 : 0

  project = var.project
  env     = var.env

  domain_name = var.domain_name
}

module "alb" {
  source = "../../modules/alb"

  project = var.project
  env     = var.env

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  app_port              = var.app_port

  # Se HTTPS estiver habilitado, pega o ARN do módulo domain. Se não, passa string vazia.
  certificate_arn = var.enable_https ? module.domain[0].certificate_arn : ""
}

resource "aws_route53_record" "alb_alias" {
  count   = var.enable_https ? 1 : 0
  zone_id = module.domain[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

module "ecs" {
  source = "../../modules/ecs"

  project = var.project
  env     = var.env

  region = var.region

  # MUDANÇA CRÍTICA: Usando subnets PÚBLICAS para o ECS ter acesso à internet (Datadog)
  # sem pagar NAT Gateway.
  private_subnet_ids    = module.network.public_subnet_ids

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

  datadog_api_key = var.datadog_api_key

  # Mantendo o uso do ECR Privado para a imagem do Datadog (Mirror)
  datadog_image = "${module.ecr_datadog.repository_url}:latest"
}

module "codedeploy" {
  source = "../../modules/codedeploy_ecs"

  project = var.project
  env     = var.env

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  listener_arn  = module.alb.listener_arn
  blue_tg_name  = module.alb.blue_target_group_name
  green_tg_name = module.alb.green_target_group_name
}

module "apigateway" {
  source = "../../modules/apigateway"

  project = var.project
  env     = var.env

  alb_listener_arn   = module.alb.listener_arn
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.vpce_sg_id] # Reutilizando SG de endpoints internos
}


module "github_oidc" {
  source = "../../modules/github_oidc"

  project = var.project
  env     = var.env
  region  = var.region

  github_owner = var.github_owner
  github_repo  = var.github_repo

  ecr_repo_arn = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${module.ecr.repository_name}"

  codedeploy_app_name         = module.codedeploy.codedeploy_app_name
  codedeploy_deployment_group = module.codedeploy.codedeploy_deployment_group
}

data "aws_caller_identity" "current" {}
