import unittest
import json
import os
from unittest.mock import patch, MagicMock
from decimal import Decimal

# Set up environment variables for testing
os.environ['ORDERS_TABLE'] = 'test-orders'
os.environ['DLQ_URL'] = 'https://sqs.us-east-1.amazonaws.com/123456789/test-dlq'

from src.lambda.order_fulfillment.lambda_function import (
    lambda_handler, process_fulfillment, update_order_status,
    check_inventory, reserve_inventory, process_payment, create_shipment
)

class TestOrderFulfillment(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures"""
        self.valid_order = {
            'order_id': 'ORDER123',
            'customer_id': 'CUST123',
            'items': [
                {
                    'product_id': 'PROD001',
                    'quantity': 2,
                    'price': Decimal('29.99'),
                    'total': Decimal('59.98')
                }
            ],
            'total_amount': Decimal('59.98'),
            'status': 'VALIDATED'
        }
    
    def test_check_inventory_success(self):
        """Test successful inventory check"""
        items = [{'product_id': 'PROD001', 'quantity': 5}]
        result = check_inventory(items)
        self.assertTrue(result['available'])
    
    def test_check_inventory_insufficient(self):
        """Test inventory check with insufficient stock"""
        items = [{'product_id': 'PROD001', 'quantity': 15}]  # High quantity
        result = check_inventory(items)
        self.assertFalse(result['available'])
        self.assertIn('available 10', result['message'])
    
    def test_reserve_inventory_success(self):
        """Test successful inventory reservation"""
        items = [{'product_id': 'PROD001', 'quantity': 2}]
        result = reserve_inventory(items)
        self.assertTrue(result['success'])
    
    def test_process_payment_success(self):
        """Test successful payment processing"""
        order = {'order_id': 'ORDER123', 'total_amount': Decimal('59.98')}
        result = process_payment(order)
        self.assertTrue(result['success'])
    
    def test_process_payment_failure(self):
        """Test payment failure for high amounts"""
        order = {'order_id': 'ORDER123', 'total_amount': Decimal('1500.00')}
        result = process_payment(order)
        self.assertFalse(result['success'])
        self.assertIn('amount exceeds limit', result['error'])
    
    def test_create_shipment_success(self):
        """Test successful shipment creation"""
        result = create_shipment(self.valid_order)
        self.assertTrue(result['success'])
        self.assertIn('tracking_number', result)
        self.assertTrue(result['tracking_number'].startswith('TRK'))
    
    @patch('src.lambda.order_fulfillment.lambda_function.orders_table')
    def test_update_order_status(self, mock_table):
        """Test order status update"""
        mock_table.update_item.return_value = {}
        
        update_order_status('ORDER123', 'PROCESSING')
        
        mock_table.update_item.assert_called_once()
        call_args = mock_table.update_item.call_args
        self.assertEqual(call_args[1]['Key']['order_id'], 'ORDER123')
    
    @patch('src.lambda.order_fulfillment.lambda_function.update_order_status')
    @patch('src.lambda.order_fulfillment.lambda_function.process_fulfillment')
    def test_lambda_handler_success(self, mock_process, mock_update):
        """Test successful lambda handler execution"""
        event = {'order': self.valid_order}
        context = MagicMock()
        
        mock_process.return_value = {
            'success': True,
            'tracking_number': 'TRK12345678'
        }
        
        result = lambda_handler(event, context)
        
        self.assertEqual(result['statusCode'], 200)
        self.assertEqual(result['status'], 'FULFILLED')
        self.assertEqual(result['tracking_number'], 'TRK12345678')
    
    @patch('src.lambda.order_fulfillment.lambda_function.update_order_status')
    @patch('src.lambda.order_fulfillment.lambda_function.process_fulfillment')
    @patch('src.lambda.order_fulfillment.lambda_function.send_to_dlq')
    def test_lambda_handler_fulfillment_failure(self, mock_dlq, mock_process, mock_update):
        """Test lambda handler with fulfillment failure"""
        event = {'order': self.valid_order}
        context = MagicMock()
        
        mock_process.return_value = {
            'success': False,
            'error': 'Payment failed'
        }
        
        result = lambda_handler(event, context)
        
        self.assertEqual(result['statusCode'], 400)
        self.assertEqual(result['status'], 'FAILED')
        self.assertIn('Payment failed', result['error'])
        mock_dlq.assert_called_once()

if __name__ == '__main__':
    unittest.main()
