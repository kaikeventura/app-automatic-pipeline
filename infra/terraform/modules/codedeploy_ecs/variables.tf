variable "project" { type = string }
variable "env"     { type = string }

variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }

variable "listener_arn" { type = string }

variable "blue_tg_name"  { type = string }
variable "green_tg_name" { type = string }
