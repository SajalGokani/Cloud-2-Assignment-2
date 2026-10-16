#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="000000000000"
API_NAME="coupons"
RESOURCE_PATH="coupons_poc"
LAMBDA_NAME="coupons_list"

echo "1. Creating REST API: $API_NAME..."
API_ID=$(awslocal apigateway create-rest-api --name "$API_NAME" --query 'id' --output text)
echo "API ID: $API_ID"

echo "2. Getting root resource ID..."
PARENT_ID=$(awslocal apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)
echo "Parent Resource ID: $PARENT_ID"

echo "3. Creating resource /$RESOURCE_PATH..."
RESOURCE_ID=$(awslocal apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$PARENT_ID" \
  --path-part "$RESOURCE_PATH" \
  --query 'id' --output text)
echo "Created Resource ID: $RESOURCE_ID"

echo "4. Creating GET method..."
awslocal apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --authorization-type "NONE"

echo "5. Integrating GET method with Lambda function..."
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}"
INTEGRATION_URI="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

awslocal apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$INTEGRATION_URI"

echo "6. Granting API Gateway permission to invoke Lambda..."
awslocal lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id "apigateway-get-coupons-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/*" || true

echo "7. Deploying API to 'prod' stage..."
awslocal apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod

echo "$API_ID" > api_id.txt

ENDPOINT_URL="http://localhost:4566/restapis/${API_ID}/prod/_user_request_/${RESOURCE_PATH}"
echo "--------------------------------------------------"
echo "API Endpoint live at:"
echo "$ENDPOINT_URL"
echo "--------------------------------------------------"
