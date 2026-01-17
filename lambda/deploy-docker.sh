#!/bin/bash
# Docker Image Deployment Script for Lambda
# Builds and pushes Docker image to ECR, then updates Lambda function

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION="ap-northeast-2"
ACCOUNT_ID="182043863214"
REPO_NAME="lotto-automation-prod"
FUNCTION_NAME="lotto-automation-prod"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}"

echo "=== Lambda Docker Deployment ==="
echo "Region: ${REGION}"
echo "ECR Repository: ${ECR_URI}"
echo ""

# Step 1: ECR Login
echo "Step 1: Logging in to ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Step 2: Build Docker image (x86_64 for Lambda)
echo ""
echo "Step 2: Building Docker image..."
cd "${SCRIPT_DIR}"
docker build --platform linux/amd64 -t ${REPO_NAME}:latest .

# Step 3: Tag and push to ECR
echo ""
echo "Step 3: Pushing to ECR..."
docker tag ${REPO_NAME}:latest ${ECR_URI}:latest
docker push ${ECR_URI}:latest

# Step 4: Update Lambda function
echo ""
echo "Step 4: Updating Lambda function..."
aws lambda update-function-code \
    --function-name ${FUNCTION_NAME} \
    --image-uri ${ECR_URI}:latest \
    --region ${REGION}

# Step 5: Wait for update to complete
echo ""
echo "Step 5: Waiting for Lambda update to complete..."
aws lambda wait function-updated --function-name ${FUNCTION_NAME} --region ${REGION}

echo ""
echo "=== Deployment Complete ==="
echo "Function: ${FUNCTION_NAME}"
echo "Image: ${ECR_URI}:latest"
