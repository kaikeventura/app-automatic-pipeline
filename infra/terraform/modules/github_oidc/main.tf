locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# Provider OIDC do GitHub (1x por conta; ok criar aqui pro dev)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # só main (barato e seguro)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "${local.name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "policy" {
  # ECR push
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }

  # CodeDeploy deploy
  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplication",
      "codedeploy:GetDeploymentGroup"
    ]
    resources = ["*"]
  }

  # ECS/ALB read (às vezes necessário em scripts de deploy)
  statement {
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::729591273848:role/app-automatic-pipeline-dev-ecs-exec-role",
      "arn:aws:iam::729591273848:role/app-automatic-pipeline-dev-ecs-task-role"
    ]
  }

  statement {
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "github" {
  name   = "${local.name}-github-actions-policy"
  policy = data.aws_iam_policy_document.policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github.name
  policy_arn = aws_iam_policy.github.arn
}

output "github_role_arn" {
  value = aws_iam_role.github.arn
}
