import json
import os
import boto3

endpoint_url = os.environ.get('AWS_ENDPOINT_URL', 'http://localhost:4566')
dynamodb = boto3.resource('dynamodb', endpoint_url=endpoint_url, region_name='us-east-1')
table = dynamodb.Table('coupons')

def handler(event, context):
    try:
        # Extract path parameter 'id'
        path_params = event.get('pathParameters') or {}
        coupon_id = path_params.get('id')
        
        if not coupon_id:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "Missing 'id' path parameter"})
            }
        
        # Extract body
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)
            
        if not body:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "Request body cannot be empty"})
            }

        # Build update expression dynamically
        update_expr = "SET "
        expr_attr_values = {}
        expr_attr_names = {}
        
        for key, value in body.items():
            if key == 'id':
                continue # Skip primary key update
            safe_key = f"#{key}"
            val_key = f":{key}"
            update_expr += f"{safe_key} = {val_key}, "
            expr_attr_names[safe_key] = key
            expr_attr_values[val_key] = value

        update_expr = update_expr.rstrip(", ")

        # Perform update in DynamoDB
        response = table.update_item(
            Key={'id': coupon_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues="ALL_NEW"
        )

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps(response.get('Attributes', {}))
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
