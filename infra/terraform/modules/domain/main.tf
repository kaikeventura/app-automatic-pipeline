locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# 1. Cria a Hosted Zone no Route53 (ou importa se já existir e for gerenciada)
# Se você comprou o domínio na AWS, a zona já existe, mas para o Terraform gerenciar,
# ou usamos 'data' (se não quisermos gerenciar) ou importamos.
# Como deu erro no 'data', vou assumir que precisamos criar ou que o nome estava errado.
# Vou mudar para resource para garantir que ela exista.
resource "aws_route53_zone" "this" {
  name = var.domain_name
  tags = local.tags
}

# 2. Cria o certificado ACM
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Se quiser suportar subdomínios (ex: *.kaikeventura.com)
  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# 3. Cria o registro DNS para validação do certificado
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}

# 4. Aguarda a validação do certificado
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

output "zone_id" {
  value = aws_route53_zone.this.zone_id
}
