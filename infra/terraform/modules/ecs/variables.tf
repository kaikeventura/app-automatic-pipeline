variable "project" { type = string }
variable "env"     { type = string }

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ecr_image" {
  type        = string
  description = "ECR image URI (will be updated by pipeline). Use placeholder for now."
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
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
