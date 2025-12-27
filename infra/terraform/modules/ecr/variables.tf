variable "project" { type = string }
variable "env"     { type = string }

variable "repo_name" {
  type = string
}

# Mantém poucas imagens pra economizar storage
variable "max_images" {
  type    = number
  default = 15
}
