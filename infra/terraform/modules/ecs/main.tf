locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# =====================
# ECS Cluster
# =====================
resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

# =====================
# CloudWatch Log Group (barato, necessário)
# =====================
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}-api"
  retention_in_days = 1
  tags              = local.tags
}

# =====================
# IAM Roles
# =====================

# Execution Role (ECR pull + logs)
data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "task_execution_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role (S3, SQS, Secrets)
resource "aws_iam_role" "task" {
  name               = "${local.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    sid     = "ReadDbSecret"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  statement {
    sid     = "S3Access"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid     = "SqsAccess"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task_policy" {
  name   = "${local.name}-ecs-task-policy"
  policy = data.aws_iam_policy_document.task_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "task_attach" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_policy.arn
}

# =====================
# Task Definition
# =====================
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  cpu    = tostring(var.cpu)
  memory = tostring(var.memory)

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode(
    concat(
      [
        {
          name      = "api"
          image     = var.ecr_image
          essential = true

          portMappings = [
            { containerPort = var.app_port, hostPort = var.app_port, protocol = "tcp" }
          ]

          environment = [
            { name = "AWS_REGION", value = var.region },
            { name = "S3_BUCKET", value = var.s3_bucket_name },
            { name = "SQS_QUEUE_PAYMENT_PROCESSING_URL", value = var.sqs_payment_processing_queue_url },
            { name = "SQS_QUEUE_PAYMENT_RESULT_URL", value = var.sqs_payment_result_queue_url },
            { name = "DB_HOST", value = var.db_host },
            { name = "DB_PORT", value = "5432" },
            { name = "DB_NAME", value = var.db_name }
          ]

          secrets = [
            { name = "DB_USERNAME", valueFrom = "${var.db_secret_arn}:username::" },
            { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" }
          ]

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.app.name
              awslogs-region        = var.region
              awslogs-stream-prefix = "api"
            }
          }
        }
      ],
      var.datadog_api_key != "" ? [
        {
          name      = "datadog-agent"
          image     = "public.ecr.aws/datadog/agent:latest"
          essential = true
          environment = [
            { name = "DD_API_KEY", value = var.datadog_api_key },
            { name = "ECS_FARGATE", value = "true" },
            { name = "DD_SITE", value = "datadoghq.com" }
          ]
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = aws_cloudwatch_log_group.app.name
              awslogs-region        = var.region
              awslogs-stream-prefix = "datadog"
            }
          }
        }
      ] : []
    )
  )

  tags = local.tags
}

# =====================
# ECS Service (já preparado pra CodeDeploy)
# =====================
resource "aws_ecs_service" "this" {
  name            = "${local.name}-api-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  }

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = var.app_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer, # Adicionado para evitar conflito com CodeDeploy
      network_configuration # Opcional, mas bom para evitar conflitos se o CodeDeploy mudar algo
    ]
  }


  tags = local.tags
}

data "aws_iam_policy_document" "execution_extra" {
  statement {
    sid     = "ReadDbSecret"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_policy" "execution_extra" {
  name   = "${local.name}-ecs-exec-extra"
  policy = data.aws_iam_policy_document.execution_extra.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "execution_extra_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.execution_extra.arn
}
