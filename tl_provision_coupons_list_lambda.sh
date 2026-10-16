#!/bin/bash
set -e

FUNCTION_NAME="coupons_list"
ROLE_ARN="arn:aws:iam::000000000000:role/coupons_lambda_role"

echo "1. Packaging Lambda code..."
zip -r function.zip index.py tl_sample_coupons_list_response.json

echo "2. Registering Lambda Function: $FUNCTION_NAME in LocalStack..."
awslocal lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.11 \
  --role "$ROLE_ARN" \
  --handler index.handler \
  --zip-file fileb://function.zip

echo "Lambda function $FUNCTION_NAME successfully registered!"
