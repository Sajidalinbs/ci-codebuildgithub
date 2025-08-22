# SNS Topic for Build Notifications
resource "aws_sns_topic" "build_notifications" {
  name = "${local.aws_project_name}-${var.environment}-build-notifications"
  
  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-build-notifications"
    Purpose = "CI/CD Build Notifications"
  })
}

# CloudWatch Event Rule for Build State Changes
resource "aws_cloudwatch_event_rule" "codebuild_state_change" {
  count = length(var.build_notification_emails) > 0 ? 1 : 0
  
  name        = "${local.aws_project_name}-${var.environment}-build-state-change"
  description = "Capture CodeBuild build state changes"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      "project-name" = ["${local.aws_project_name}-${var.environment}-build"]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-build-events"
  })
}

# CloudWatch Event Target to SNS
resource "aws_cloudwatch_event_target" "codebuild_sns_target" {
  count = length(var.build_notification_emails) > 0 ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.codebuild_state_change[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.build_notifications.arn

  input_transformer {
    input_paths = {
      status = "$.detail.build-status"
      name = "$.detail.project-name"
      build_id = "$.detail.build-id"
      time = "$.time"
      region = "$.region"
    }
    input_template = <<EOF
{
  "message": "CodeBuild: <name> - Status: <status> at <time> (<region>)",
  "build_id": "<build_id>",
  "project_name": "<name>",
  "build_status": "<status>",
  "timestamp": "<time>",
  "region": "<region>"
}
EOF
  }
}

# SNS Topic Policy for CloudWatch Events access
resource "aws_sns_topic_policy" "build_notifications_policy" {
  arn = aws_sns_topic.build_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.build_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount": data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email Subscriptions for Build Notifications
resource "aws_sns_topic_subscription" "build_notifications_email" {
  count     = length(var.build_notification_emails)
  topic_arn = aws_sns_topic.build_notifications.arn
  protocol  = "email"
  endpoint  = var.build_notification_emails[count.index]
}
