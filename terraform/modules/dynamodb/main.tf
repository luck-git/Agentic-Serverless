resource "aws_dynamodb_table" "orders" {
  name         = coalesce(var.orders_table_name, "${var.project_name}-${var.environment}-orders")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"
  
  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "order_date"
    type = "S"
  }

  global_secondary_index {
    name            = "CustomerIndex"
    hash_key        = "customer_id"
    range_key       = "order_date"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name        = coalesce(var.orders_table_name, "${var.project_name}-${var.environment}-orders")
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}