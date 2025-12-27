locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

resource "aws_ecr_repository" "this" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, { Name = "${local.name}-ecr-${var.repo_name}" })
}

# Limpa imagens antigas pra economizar
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last ${var.max_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  value = aws_ecr_repository.this.name
}
