import json
import boto3
import os
import logging
from datetime import datetime
from decimal import Decimal
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# Environment variables
ORDERS_TABLE = os.environ['ORDERS_TABLE']
ORDER_QUEUE_URL = os.environ['ORDER_QUEUE_URL']

# Initialize DynamoDB table
orders_table = dynamodb.Table(ORDERS_TABLE)

class OrderValidationError(Exception):
    """Custom exception for order validation errors"""
    pass

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Validates incoming orders and stores them in DynamoDB
    
    Args:
        event: Lambda event containing order data
        context: Lambda context
        
    Returns:
        Dict containing status and order details
    """
    try:
        logger.info(f"Processing order validation: {json.dumps(event)}")
        
        # Extract order data from event
        order_data = event.get('order', {})
        
        # Validate order
        validated_order = validate_order(order_data)
        
        # Store order in DynamoDB
        stored_order = store_order(validated_order)
        
        # Send to processing queue
        queue_order(stored_order)
        
        logger.info(f"Order validated successfully: {stored_order['order_id']}")
        
        return {
            'statusCode': 200,
            'status': 'VALIDATED',
            'order': stored_order,
            'message': 'Order validated and queued for processing'
        }
        
    except OrderValidationError as e:
        logger.error(f"Order validation failed: {str(e)}")
        return {
            'statusCode': 400,
            'status': 'VALIDATION_FAILED',
            'error': str(e),
            'message': 'Order validation failed'
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'status': 'ERROR',
            'error': 'Internal server error',
            'message': 'An unexpected error occurred'
        }

def validate_order(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validates order data and returns normalized order
    
    Args:
        order_data: Raw order data
        
    Returns:
        Validated and normalized order data
        
    Raises:
        OrderValidationError: If validation fails
    """
    required_fields = ['customer_id', 'items', 'total_amount']
    
    # Check required fields
    for field in required_fields:
        if field not in order_data:
            raise OrderValidationError(f"Missing required field: {field}")
    
    # Validate customer_id
    customer_id = order_data['customer_id']
    if not isinstance(customer_id, str) or len(customer_id.strip()) == 0:
        raise OrderValidationError("Invalid customer_id")
    
    # Validate items
    items = order_data['items']
    if not isinstance(items, list) or len(items) == 0:
        raise OrderValidationError("Order must contain at least one item")
    
    total_calculated = Decimal('0')
    validated_items = []
    
    for item in items:
        if not all(k in item for k in ['product_id', 'quantity', 'price']):
            raise OrderValidationError("Each item must have product_id, quantity, and price")
        
        quantity = int(item['quantity'])
        price = Decimal(str(item['price']))
        
        if quantity <= 0:
            raise OrderValidationError("Item quantity must be positive")
        
        if price <= 0:
            raise OrderValidationError("Item price must be positive")
        
        item_total = price * quantity
        total_calculated += item_total
        
        validated_items.append({
            'product_id': str(item['product_id']),
            'quantity': quantity,
            'price': price,
            'total': item_total
        })
    
    # Validate total amount
    provided_total = Decimal(str(order_data['total_amount']))
    if abs(total_calculated - provided_total) > Decimal('0.01'):
        raise OrderValidationError("Total amount does not match sum of items")
    
    # Generate order ID and timestamp
    import uuid
    order_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()
    
    validated_order = {
        'order_id': order_id,
        'customer_id': customer_id.strip(),
        'items': validated_items,
        'total_amount': total_calculated,
        'status': 'VALIDATED',
        'created_at': timestamp,
        'updated_at': timestamp
    }
    
    return validated_order

def store_order(order: Dict[str, Any]) -> Dict[str, Any]:
    """
    Stores order in DynamoDB
    
    Args:
        order: Validated order data
        
    Returns:
        Stored order data
    """
    try:
        # Convert Decimal values for DynamoDB
        order_item = json.loads(json.dumps(order), parse_float=Decimal)
        
        orders_table.put_item(Item=order_item)
        logger.info(f"Order stored in DynamoDB: {order['order_id']}")
        
        return order
        
    except Exception as e:
        logger.error(f"Failed to store order: {str(e)}")
        raise

def queue_order(order: Dict[str, Any]) -> None:
    """
    Sends order to SQS queue for processing
    
    Args:
        order: Order data to queue
    """
    try:
        message_body = json.dumps(order, default=str)
        
        sqs.send_message(
            QueueUrl=ORDER_QUEUE_URL,
            MessageBody=message_body,
            MessageAttributes={
                'order_id': {
                    'StringValue': order['order_id'],
                    'DataType': 'String'
                },
                'customer_id': {
                    'StringValue': order['customer_id'],
                    'DataType': 'String'
                }
            }
        )
        
        logger.info(f"Order queued for processing: {order['order_id']}")
        
    except Exception as e:
        logger.error(f"Failed to queue order: {str(e)}")
        raise
