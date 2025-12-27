locals {
  name = "${var.project}-${var.env}-${var.queue_name}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "terraform"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "${local.name}-dlq"
  tags = local.tags
}

# Main queue
resource "aws_sqs_queue" "this" {
  name = local.name

  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.tags
}
