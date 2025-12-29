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

output "domain_name" {
  value = module.domain.domain_name
}
