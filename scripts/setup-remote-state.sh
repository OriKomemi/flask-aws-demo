#!/bin/bash
set -e

AWS_REGION="us-east-1"
BUCKET_NAME="flask-aws-demo-terraform-state"
TABLE_NAME="flask-aws-demo-terraform-locks"

echo "Creating S3 bucket: $BUCKET_NAME"

if [ "$AWS_REGION" == "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION || true
else
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION || true
fi

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION || true

echo "✅ Remote state backend ready"
