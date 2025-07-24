output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.order_workflow.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.order_workflow.name
}

output "execution_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions_role.arn
}

output "api_gateway_role_arn" {
  description = "ARN of the API Gateway role for Step Functions"
  value       = aws_iam_role.api_gateway_role.arn
}