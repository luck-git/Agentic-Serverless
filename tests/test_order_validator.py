
import unittest
import json
import os
from unittest.mock import patch, MagicMock
from decimal import Decimal

# Set up environment variables for testing
os.environ['ORDERS_TABLE'] = 'test-orders'
os.environ['ORDER_QUEUE_URL'] = 'https://sqs.us-east-1.amazonaws.com/123456789/test-queue'

# Import the lambda function after setting environment variables
from src.lambda.order_validator.lambda_function import (
    lambda_handler, validate_order, store_order, queue_order,
    OrderValidationError
)

class TestOrderValidator(unittest.TestCase):

    def setUp(self):
        """Set up test fixtures"""
        self.valid_order = {
            'customer_id': 'CUST123',
            'items': [
                {
                    'product_id': 'PROD001',
                    'quantity': 2,
                    'price': 29.99
                },
                {
                    'product_id': 'PROD002',
                    'quantity': 1,
                    'price': 15.50
                }
            ],
            'total_amount': 75.48
        }

    def test_validate_order_success(self):
        """Test successful order validation"""
        result = validate_order(self.valid_order)

        self.assertIn('order_id', result)
        self.assertEqual(result['customer_id'], 'CUST123')
        self.assertEqual(result['status'], 'VALIDATED')
        self.assertEqual(len(result['items']), 2)
        self.assertEqual(result['total_amount'], Decimal('75.48'))

    def test_validate_order_missing_customer_id(self):
        """Test validation failure when customer_id is missing"""
        invalid_order = self.valid_order.copy()
        del invalid_order['customer_id']

        with self.assertRaises(OrderValidationError) as context:
            validate_order(invalid_order)

        self.assertIn('Missing required field: customer_id', str(context.exception))

    def test_validate_order_empty_items(self):
        """Test validation failure when items list is empty"""
        invalid_order = self.valid_order.copy()
        invalid_order['items'] = []

        with self.assertRaises(OrderValidationError) as context:
            validate_order(invalid_order)

        self.assertIn('Order must contain at least one item', str(context.exception))

    def test_validate_order_total_mismatch(self):
        """Test validation failure when total doesn't match sum of items"""
        invalid_order = self.valid_order.copy()
        invalid_order['total_amount'] = 100.00  # Wrong total

        with self.assertRaises(OrderValidationError) as context:
            validate_order(invalid_order)

        self.assertIn('Total amount does not match sum of items', str(context.exception))

    def test_validate_order_negative_quantity(self):
        """Test validation failure for negative quantity"""
        invalid_order = self.valid_order.copy()
        invalid_order['items'][0]['quantity'] = -1

        with self.assertRaises(OrderValidationError) as context:
            validate_order(invalid_order)

        self.assertIn('Item quantity must be positive', str(context.exception))

    def test_validate_order_negative_price(self):
        """Test validation failure for negative price"""
        invalid_order = self.valid_order.copy()
        invalid_order['items'][0]['price'] = -10.00

        with self.assertRaises(OrderValidationError) as context:
            validate_order(invalid_order)

        self.assertIn('Item price must be positive', str(context.exception))

    @patch('src.lambda.order_validator.lambda_function.orders_table')
    @patch('src.lambda.order_validator.lambda_function.sqs')
    def test_lambda_handler_success(self, mock_sqs, mock_table):
        """Test successful lambda handler execution"""
        event = {
            'order': self.valid_order
        }
        context = MagicMock()

        # Mock DynamoDB put_item
        mock_table.put_item.return_value = {}

        # Mock SQS send_message
        mock_sqs.send_message.return_value = {}

        result = lambda_handler(event, context)

        self.assertEqual(result['statusCode'], 200)
        self.assertEqual(result['status'], 'VALIDATED')
        self.assertIn('order', result)
        self.assertEqual(result['message'], 'Order validated and queued for processing')

    @patch('src.lambda.order_validator.lambda_function.orders_table')
    @patch('src.lambda.order_validator.lambda_function.sqs')
    def test_lambda_handler_validation_failure(self, mock_sqs, mock_table):
        """Test lambda handler with validation failure"""
        event = {
            'order': {
                'customer_id': '',  # Invalid customer_id
                'items': [],
                'total_amount': 0
            }
        }
        context = MagicMock()

        result = lambda_handler(event, context)

        self.assertEqual(result['statusCode'], 400)
        self.assertEqual(result['status'], 'VALIDATION_FAILED')
        self.assertIn('error', result)

if __name__ == '__main__':
    unittest.main()
