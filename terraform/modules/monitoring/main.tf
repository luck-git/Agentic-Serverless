resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "${var.prefix}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace          = "AWS/SQS"
  period             = 300
  statistic          = "Sum"
  threshold          = 0
  alarm_description   = "Triggers when messages are in the DLQ"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags

  dimensions = {
    QueueName = split("/", var.dlq_arn)[length(split("/", var.dlq_arn)) - 1]
  }
}

resource "aws_cloudwatch_metric_alarm" "step_function_failures" {
  alarm_name          = "${var.prefix}-sfn-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace          = "AWS/States"
  period             = 300
  statistic          = "Sum"
  threshold          = 0
  alarm_description   = "Triggers when Step Function executions fail"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags

  dimensions = {
    StateMachineArn = var.step_function_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_errors" {
  count               = var.api_gateway_id != "" ? 1 : 0
  alarm_name          = "${var.prefix}-api-gw-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace          = "AWS/ApiGateway"
  period             = 300
  statistic          = "Sum"
  threshold          = 0
  alarm_description   = "Triggers when API Gateway returns 5XX errors"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  tags               = var.tags

  dimensions = {
    ApiId = var.api_gateway_id
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${var.prefix}-alerts-topic"
  tags = var.tags
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts.arn]
  }
}