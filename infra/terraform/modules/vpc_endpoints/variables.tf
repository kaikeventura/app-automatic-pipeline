variable "project" { type = string }
variable "env"     { type = string }

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "route_table_ids" {
  type = list(string)
}

variable "vpce_security_group_id" { type = string }
