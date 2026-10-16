#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID="000000000000"
FUNCTION_NAME="coupons_update"
ROLE_ARN="arn:aws:iam::000000000000:role/coupons_lambda_role"
API_ID=$(cat api_id.txt)
ID_RESOURCE_ID=$(cat id_resource_id.txt)

echo "1. Packaging Lambda code for $FUNCTION_NAME..."
zip -q update.zip coupons_update.py

echo "2. Registering/Updating Lambda Function $FUNCTION_NAME in LocalStack..."
awslocal lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler coupons_update.handler \
  --zip-file fileb://update.zip > /dev/null 2>&1 || \
awslocal lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://update.zip > /dev/null 2>&1

echo "3. Creating PUT method on /{id}..."
awslocal apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$ID_RESOURCE_ID" \
  --http-method PUT \
  --authorization-type "NONE" > /dev/null 2>&1 || true

echo "4. Integrating PUT method with $FUNCTION_NAME..."
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"
INTEGRATION_URI="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

awslocal apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$ID_RESOURCE_ID" \
  --http-method PUT \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$INTEGRATION_URI" > /dev/null 2>&1

echo "5. Adding Lambda permission..."
awslocal lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "apigateway-update-by-id-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/*" > /dev/null 2>&1 || true

echo "6. Redeploying API stage..."
awslocal apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod > /dev/null 2>&1

echo "coupons_update Lambda and PUT endpoint successfully provisioned!"
