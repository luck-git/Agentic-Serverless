output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic for alert notifications"
  value       = aws_sns_topic.alerts.arn
}

output "dlq_alarm_name" {
  description = "Name of the DLQ messages alarm"
  value       = aws_cloudwatch_metric_alarm.dlq_alarm.alarm_name
}

output "sfn_alarm_name" {
  description = "Name of the Step Function failures alarm"
  value       = aws_cloudwatch_metric_alarm.step_function_failures.alarm_name
}