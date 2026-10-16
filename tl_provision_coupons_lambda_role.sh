#!/bin/bash
set -e

ROLE_NAME="coupons_lambda_role"
POLICY_NAME="coupons_lambda_policy"

echo "1. Creating IAM Role: $ROLE_NAME..."
awslocal iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

echo "2. Putting Inline IAM Policy onto Role..."
awslocal iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file://coupons_policy.json

echo "IAM Role $ROLE_NAME successfully provisioned in LocalStack!"
