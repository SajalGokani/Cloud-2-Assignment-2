import json
import os
import boto3

# Initialize DynamoDB resource pointing to LocalStack
endpoint_url = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost:4566')
dynamodb = boto3.resource('dynamodb', endpoint_url=endpoint_url, region_name='us-east-1')
table = dynamodb.Table('coupons')

def handler(event, context):
    try:
        # Extract path parameter 'id' from API Gateway event
        path_params = event.get('pathParameters') or {}
        coupon_id = path_params.get('id')
        
        if not coupon_id:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "Missing 'id' path parameter"})
            }
        
        # Query DynamoDB table
        response = table.get_item(Key={'id': coupon_id})
        item = response.get('Item')
        
        if not item:
            return {
                "statusCode": 404,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": f"Coupon with id '{coupon_id}' not found"})
            }
            
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps(item)
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
