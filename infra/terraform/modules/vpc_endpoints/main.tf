locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# =====================
# S3 (Gateway endpoint) - GRÁTIS
# =====================
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.route_table_ids

  tags = merge(local.tags, { Name = "${local.name}-vpce-s3" })
}

# =====================
# Interface endpoints
# =====================
locals {
  interface_services = {
    ecr_api        = "com.amazonaws.us-east-1.ecr.api"
    ecr_dkr        = "com.amazonaws.us-east-1.ecr.dkr"
    logs           = "com.amazonaws.us-east-1.logs"
    secretsmanager = "com.amazonaws.us-east-1.secretsmanager"
    sqs            = "com.amazonaws.us-east-1.sqs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_services

  vpc_id            = var.vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.vpce_security_group_id]

  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${local.name}-vpce-${each.key}"
  })
}
