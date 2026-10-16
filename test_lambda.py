import unittest
import json
from index import handler

class TestCouponsLambda(unittest.TestCase):
    def test_handler_success(self):
        # Mock API Gateway event and context
        event = {}
        context = {}
        
        # Invoke handler
        response = handler(event, context)
        
        # Assertions
        self.assertEqual(response['statusCode'], 200)
        self.assertIn('Content-Type', response['headers'])
        self.assertEqual(response['headers']['Content-Type'], 'application/json')
        
        # Parse body and verify structure
        body = json.loads(response['body'])
        self.assertIn('coupons', body)
        self.assertIsInstance(body['coupons'], list)
        self.assertGreater(len(body['coupons']), 0)
        
        # Verify fields of the first item
        first_coupon = body['coupons'][0]
        self.assertIn('id', first_coupon)
        self.assertIn('code', first_coupon)
        self.assertIn('discount', first_coupon)

if __name__ == '__main__':
    unittest.main()
