variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ecr_image" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_secret_arn" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "sqs_payment_processing_queue_url" {
  type = string
}

variable "sqs_payment_result_queue_url" {
  type = string
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "datadog_api_key" {
  description = "API Key do Datadog"
  type        = string
  sensitive   = true
  default     = "" # Opcional, se não passar, não configura o sidecar (lógica a ser implementada)
}

variable "datadog_image" {
  description = "Imagem do Datadog Agent (pode ser pública ou privada)"
  type        = string
  default     = "public.ecr.aws/datadog/agent:latest"
}

variable "datadog_site" {
  description = "Site do Datadog (ex: datadoghq.com, us5.datadoghq.com, datadoghq.eu)"
  type        = string
  default     = "datadoghq.com"
}
