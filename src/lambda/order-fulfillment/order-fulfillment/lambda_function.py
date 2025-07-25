import json
import boto3
import os
import logging
from datetime import datetime
from decimal import Decimal
from typing import Dict, Any, List

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# Environment variables
ORDERS_TABLE = os.environ['ORDERS_TABLE']
DLQ_URL = os.environ['DLQ_URL']

# Initialize DynamoDB table
orders_table = dynamodb.Table(ORDERS_TABLE)

class FulfillmentError(Exception):
    """Custom exception for fulfillment errors"""
    pass

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Processes order fulfillment
    
    Args:
        event: Lambda event containing order data
        context: Lambda context
        
    Returns:
        Dict containing fulfillment status
    """
    try:
        logger.info(f"Processing order fulfillment: {json.dumps(event)}")
        
        # Extract order data
        if 'order' in event:
            order_data = event['order']
        else:
            # Handle SQS event format
            order_data = json.loads(event['Records'][0]['body'])
        
        order_id = order_data['order_id']
        
        # Update order status to processing
        update_order_status(order_id, 'PROCESSING')
        
        # Process fulfillment steps
        fulfillment_result = process_fulfillment(order_data)
        
        if fulfillment_result['success']:
            # Update order status to fulfilled
            update_order_status(order_id, 'FULFILLED', fulfillment_result['tracking_number'])
            
            logger.info(f"Order fulfilled successfully: {order_id}")
            
            return {
                'statusCode': 200,
                'status': 'FULFILLED',
                'order_id': order_id,
                'tracking_number': fulfillment_result['tracking_number'],
                'message': 'Order fulfilled successfully'
            }
        else:
            # Update order status to failed
            update_order_status(order_id, 'FAILED', error=fulfillment_result['error'])
            
            # Send to DLQ for manual review
            send_to_dlq(order_data, fulfillment_result['error'])
            
            return {
                'statusCode': 400,
                'status': 'FAILED',
                'order_id': order_id,
                'error': fulfillment_result['error'],
                'message': 'Order fulfillment failed'
            }
            
    except Exception as e:
        logger.error(f"Unexpected error in fulfillment: {str(e)}")
        
        # Try to update order status
        try:
            if 'order_id' in locals():
                update_order_status(order_id, 'FAILED', error=str(e))
        except:
            pass
            
        return {
            'statusCode': 500,
            'status': 'ERROR',
            'error': 'Internal server error',
            'message': 'An unexpected error occurred during fulfillment'
        }

def update_order_status(order_id: str, status: str, tracking_number: str = None, error: str = None) -> None:
    """
    Updates order status in DynamoDB
    
    Args:
        order_id: Order ID to update
        status: New status
        tracking_number: Optional tracking number
        error: Optional error message
    """
    try:
        update_expression = "SET #status = :status, updated_at = :updated_at"
        expression_values = {
            ':status': status,
            ':updated_at': datetime.utcnow().isoformat()
        }
        expression_names = {'#status': 'status'}
        
        if tracking_number:
            update_expression += ", tracking_number = :tracking_number"
            expression_values[':tracking_number'] = tracking_number
            
        if error:
            update_expression += ", error_message = :error"
            expression_values[':error'] = error
        
        orders_table.update_item(
            Key={'order_id': order_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ExpressionAttributeNames=expression_names
        )
        
        logger.info(f"Updated order {order_id} status to {status}")
        
    except Exception as e:
        logger.error(f"Failed to update order status: {str(e)}")
        raise

def process_fulfillment(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Processes the actual fulfillment steps
    
    Args:
        order_data: Order data to fulfill
        
    Returns:
        Dict with success status and details
    """
    try:
        order_id = order_data['order_id']
        items = order_data['items']
        
        # Step 1: Check inventory
        inventory_check = check_inventory(items)
        if not inventory_check['available']:
            return {
                'success': False,
                'error': f"Insufficient inventory: {inventory_check['message']}"
            }
        
        # Step 2: Reserve inventory
        reservation_result = reserve_inventory(items)
        if not reservation_result['success']:
            return {
                'success': False,
                'error': f"Failed to reserve inventory: {reservation_result['error']}"
            }
        
        # Step 3: Process payment (simulation)
        payment_result = process_payment(order_data)
        if not payment_result['success']:
            # Release reserved inventory
            release_inventory(items)
            return {
                'success': False,
                'error': f"Payment failed: {payment_result['error']}"
            }
        
        # Step 4: Create shipment
        shipment_result = create_shipment(order_data)
        if not shipment_result['success']:
            # Release reserved inventory and refund payment
            release_inventory(items)
            refund_payment(order_data)
            return {
                'success': False,
                'error': f"Shipment creation failed: {shipment_result['error']}"
            }
        
        return {
            'success': True,
            'tracking_number': shipment_result['tracking_number']
        }
        
    except Exception as e:
        logger.error(f"Error in fulfillment processing: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def check_inventory(items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Simulates inventory checking
    """
    # Simulation: randomly fail some orders for testing
    import random
    
    for item in items:
        # Simulate out of stock for high quantities
        if item['quantity'] > 10:
            return {
                'available': False,
                'message': f"Product {item['product_id']} - requested {item['quantity']}, available 10"
            }
    
    return {'available': True}

def reserve_inventory(items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Simulates inventory reservation
    """
    # In a real system, this would update inventory management system
    logger.info(f"Reserved inventory for {len(items)} items")
    return {'success': True}

def release_inventory(items: List[Dict[str, Any]]) -> None:
    """
    Simulates inventory release
    """
    logger.info(f"Released inventory for {len(items)} items")

def process_payment(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Simulates payment processing
    """
    import random
    
    # Simulate payment failure for orders over $1000
    if float(order_data['total_amount']) > 1000:
        return {
            'success': False,
            'error': 'Payment declined - amount exceeds limit'
        }
    
    logger.info(f"Payment processed for order {order_data['order_id']}")
    return {'success': True}

def refund_payment(order_data: Dict[str, Any]) -> None:
    """
    Simulates payment refund
    """
    logger.info(f"Payment refunded for order {order_data['order_id']}")

def create_shipment(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Simulates shipment creation
    """
    import uuid
    
    tracking_number = f"TRK{str(uuid.uuid4())[:8].upper()}"
    
    logger.info(f"Shipment created for order {order_data['order_id']}: {tracking_number}")
    
    return {
        'success': True,
        'tracking_number': tracking_number
    }

def send_to_dlq(order_data: Dict[str, Any], error: str) -> None:
    """
    Sends failed order to Dead Letter Queue
    """
    try:
        message_body = json.dumps({
            'order': order_data,
            'error': error,
            'failed_at': datetime.utcnow().isoformat()
        }, default=str)
        
        sqs.send_message(
            QueueUrl=DLQ_URL,
            MessageBody=message_body
        )
        
        logger.info(f"Order sent to DLQ: {order_data['order_id']}")
        
    except Exception as e:
        logger.error(f"Failed to send to DLQ: {str(e)}")
