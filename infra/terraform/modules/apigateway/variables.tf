variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS do ALB para integração pública"
  type        = string
}

# Variáveis abaixo não são mais usadas se removermos o VPC Link, mas vou manter para não quebrar chamadas antigas por enquanto
variable "alb_listener_arn" {
  description = "ARN do listener do ALB (não usado na integração pública)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID da VPC (não usado na integração pública)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets privadas (não usado na integração pública)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security Groups (não usado na integração pública)"
  type        = list(string)
  default     = []
}
