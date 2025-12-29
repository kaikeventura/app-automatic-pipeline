variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "certificate_arn" {
  description = "ARN do certificado ACM para HTTPS"
  type        = string
  default     = "" # Opcional para não quebrar setups existentes sem HTTPS
}
