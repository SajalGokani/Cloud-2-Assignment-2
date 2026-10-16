#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="000000000000"
FUNCTION_NAME="coupons_get_by_id"
ROLE_ARN="arn:aws:iam::000000000000:role/coupons_lambda_role"
API_ID=$(cat api_id.txt)

echo "1. Packaging Lambda code for $FUNCTION_NAME..."
zip -q get_by_id.zip coupons_get_by_id.py

echo "2. Registering/Updating Lambda Function $FUNCTION_NAME in LocalStack..."
awslocal lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler coupons_get_by_id.handler \
  --zip-file fileb://get_by_id.zip > /dev/null 2>&1 || \
awslocal lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://get_by_id.zip > /dev/null 2>&1

echo "3. Fetching /coupons_poc Resource ID..."
PARENT_RESOURCE_ID=$(python3 -c "
import json, subprocess
res = subprocess.check_output(['awslocal', 'apigateway', 'get-resources', '--rest-api-id', '$API_ID'])
data = json.loads(res)
for item in data.get('items', []):
    if item.get('path') == '/coupons_poc':
        print(item['id'])
        break
")
echo "Parent Resource ID (/coupons_poc): $PARENT_RESOURCE_ID"

echo "4. Creating /{id} path parameter resource..."
ID_RESOURCE_ID=$(awslocal apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$PARENT_RESOURCE_ID" \
  --path-part "{id}" \
  --query 'id' --output text 2>/dev/null || \
python3 -c "
import json, subprocess
res = subprocess.check_output(['awslocal', 'apigateway', 'get-resources', '--rest-api-id', '$API_ID'])
data = json.loads(res)
for item in data.get('items', []):
    if item.get('path') == '/coupons_poc/{id}':
        print(item['id'])
        break
")
echo "ID Resource ID: $ID_RESOURCE_ID"

echo "5. Creating GET method on /{id}..."
awslocal apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$ID_RESOURCE_ID" \
  --http-method GET \
  --authorization-type "NONE" > /dev/null 2>&1 || true

echo "6. Integrating GET method with $FUNCTION_NAME..."
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"
INTEGRATION_URI="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

awslocal apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$ID_RESOURCE_ID" \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$INTEGRATION_URI" > /dev/null 2>&1

echo "7. Adding Lambda permission..."
awslocal lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "apigateway-get-by-id-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/*" > /dev/null 2>&1 || true

echo "8. Redeploying API stage..."
awslocal apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod > /dev/null 2>&1

echo "$ID_RESOURCE_ID" > id_resource_id.txt
echo "coupons_get_by_id Lambda and endpoint successfully provisioned!"
