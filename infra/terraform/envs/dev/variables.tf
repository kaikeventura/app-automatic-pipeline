variable "project" {
  description = "Nome do projeto"
  type        = string
  default     = "app-automatic-pipeline"
}

variable "env" {
  description = "Ambiente (dev, prod, etc)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "Zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.10.20.0/24", "10.10.21.0/24"]
}

variable "app_port" {
  description = "Porta da aplicação"
  type        = number
  default     = 8080
}

variable "ecr_repo_name" {
  description = "Nome do repositório ECR"
  type        = string
  default     = "app-automatic-pipeline-api"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "ticketdb"
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "ticketuser"
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3"
  type        = string
  default     = "app-automatic-pipeline-files"
}

variable "domain_name" {
  description = "Domínio da aplicação"
  type        = string
  default     = "app-automatic-pipeline.com"
}

variable "github_owner" {
  description = "Dono do repositório GitHub"
  type        = string
  default     = "kaikeventura"
}

variable "github_repo" {
  description = "Nome do repositório GitHub"
  type        = string
  default     = "app-automatic-pipeline"
}

variable "enable_https" {
  description = "Habilita criação de domínio, certificado e HTTPS"
  type        = bool
  default     = false
}
