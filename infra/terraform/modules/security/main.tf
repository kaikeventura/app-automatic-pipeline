locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# ALB SG: expõe HTTP (80). HTTPS (443) a gente adiciona depois se for usar ACM.
resource "aws_security_group" "alb" {
  name        = "${local.name}-sg-alb"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "To ECS"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-alb" })
}

# ECS Service SG: só recebe do ALB na porta do app
resource "aws_security_group" "ecs" {
  name        = "${local.name}-sg-ecs"
  description = "ECS service security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress aberto (o controle de destino real virá via endpoints/rotas)
  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-ecs" })
}

# RDS SG: só recebe do ECS na 5432
resource "aws_security_group" "rds" {
  name        = "${local.name}-sg-rds"
  description = "RDS Postgres security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-rds" })
}


# VPCE SG: recebe HTTPS (443) SOMENTE do ECS
resource "aws_security_group" "vpce" {
  name        = "${local.name}-sg-vpce"
  description = "VPC Interface Endpoints security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-vpce" })
}
