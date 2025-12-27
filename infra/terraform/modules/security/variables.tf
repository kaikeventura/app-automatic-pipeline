variable "project" { type = string }
variable "env"     { type = string }

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}
