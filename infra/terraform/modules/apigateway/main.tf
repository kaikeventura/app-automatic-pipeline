locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# ==========================================
# VPC Link (Permite API Gateway -> ALB Privado/Interno)
# ==========================================
resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${local.name}-vpc-link"
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids

  tags = local.tags
}

# ==========================================
# API Gateway (HTTP API)
# ==========================================
resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"

  # Importante para definir o contrato via OpenAPI
  # O arquivo agora está na raiz do projeto (app/openapi.yaml)
  # path.module = infra/terraform/modules/apigateway
  # ../../../../app/openapi.yaml leva para a raiz do projeto/app/openapi.yaml
  body = templatefile("${path.module}/../../../../app/openapi.yaml", {
    vpc_link_id    = aws_apigatewayv2_vpc_link.this.id
    alb_listener_arn = var.alb_listener_arn
  })

  tags = local.tags
}

# ==========================================
# Stage (Default)
# ==========================================
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format          = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  tags = local.tags
}

# ==========================================
# Logs
# ==========================================
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = 3
  tags              = local.tags
}
