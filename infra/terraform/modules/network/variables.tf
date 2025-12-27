variable "project" { 
  type = string 
}

variable "env" { 
  type = string 
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

# Dev-friendly: 1 NAT (mais barato). Em prod, ideal é NAT por AZ.
variable "single_nat_gateway" {
  type    = bool
  default = true
}
