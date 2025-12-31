variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "alb_listener_arn" {
  description = "ARN do listener do ALB para integração"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC para criar o VPC Link (se necessário)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets privadas para o VPC Link"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups para o VPC Link"
  type        = list(string)
}
