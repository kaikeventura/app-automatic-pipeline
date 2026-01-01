locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# ==========================================
# VPC Link
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

  # Removido o body (OpenAPI) para usar recursos nativos

  tags = local.tags
}

# ==========================================
# Integração com ALB
# ==========================================
resource "aws_apigatewayv2_integration" "alb" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.alb_listener_arn

  integration_method = "ANY" # Método que o API Gateway usa para chamar o ALB
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id

  payload_format_version = "1.0"
}

# ==========================================
# Rotas
# ==========================================

resource "aws_apigatewayv2_route" "events" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "tickets" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /tickets/purchase/{eventId}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# ==========================================
# Stage (Default)
# ==========================================
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true # Com recursos nativos, auto_deploy funciona bem

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
