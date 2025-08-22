#!/bin/bash

# AWS ECR Build and Push Script
# Usage: ./scripts/build-and-push.sh <aws-region> <ecr-repository-name> [tag]

set -e

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <aws-region> <ecr-repository-name> [tag]"
    echo "Example: $0 us-west-2 memory-counter-adapter latest"
    exit 1
fi

AWS_REGION=$1
ECR_REPO_NAME=$2
TAG=${3:-latest}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: Unable to get AWS Account ID. Make sure AWS CLI is configured."
    exit 1
fi

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URI}/${ECR_REPO_NAME}:${TAG}"

echo "Building Docker image..."
docker build -t ${ECR_REPO_NAME}:${TAG} .

echo "Tagging image for ECR..."
docker tag ${ECR_REPO_NAME}:${TAG} ${FULL_IMAGE_NAME}

echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}

echo "Pushing image to ECR..."
docker push ${FULL_IMAGE_NAME}

echo "Successfully pushed ${FULL_IMAGE_NAME}"
echo "Image URI: ${FULL_IMAGE_NAME}"