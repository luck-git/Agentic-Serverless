resource "aws_dynamodb_table" "orders" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "order_id"
  
  attribute {
    name = "order_id"
    type = "S"
  }
  
  attribute {
    name = "customer_id"
    type = "S"
  }
  
  attribute {
    name = "status"
    type = "S"
  }
  
  global_secondary_index {
    name     = "CustomerIndex"
    hash_key = "customer_id"
  }
  
  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.environment}-orders-table"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

output "table_name" {
  value = aws_dynamodb_table.orders.name
}

output "table_arn" {
  value = aws_dynamodb_table.orders.arn
}
