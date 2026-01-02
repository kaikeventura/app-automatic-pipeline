locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# ==========================================
# API Gateway (HTTP API)
# ==========================================
resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

# ==========================================
# Integração com ALB (Público)
# ==========================================
resource "aws_apigatewayv2_integration" "alb" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"

  # Integração direta via internet pública
  integration_uri    = "http://${var.alb_dns_name}"
  integration_method = "ANY"

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
