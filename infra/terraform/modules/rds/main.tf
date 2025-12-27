locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# =====================
# Password segura
# =====================
resource "random_password" "db" {
  length  = 20
  special = true
}

# =====================
# Secret (credenciais DB)
# =====================
resource "aws_secretsmanager_secret" "db" {
  name = "${local.name}/rds/postgres"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
  })
}

# =====================
# Subnet group (privado)
# =====================
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = local.tags
}

# =====================
# RDS Postgres (barato)
# =====================
resource "aws_db_instance" "this" {
  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = "18.1"

  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  multi_az               = false
  publicly_accessible    = false
  backup_retention_period = 1

  skip_final_snapshot = true   # ⚠️ dev only (economia)
  deletion_protection = false

  apply_immediately = true

  tags = local.tags
}
