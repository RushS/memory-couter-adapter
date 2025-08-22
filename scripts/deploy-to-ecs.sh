#!/bin/bash

# ECS Deployment Script
# Usage: ./scripts/deploy-to-ecs.sh <aws-region> <cluster-name> <service-name> <task-definition-family> <image-uri>

set -e

if [ $# -lt 5 ]; then
    echo "Usage: $0 <aws-region> <cluster-name> <service-name> <task-definition-family> <image-uri>"
    echo "Example: $0 us-west-2 my-cluster memory-counter-service memory-counter-task 123456789.dkr.ecr.us-west-2.amazonaws.com/memory-counter-adapter:latest"
    exit 1
fi

AWS_REGION=$1
CLUSTER_NAME=$2
SERVICE_NAME=$3
TASK_DEFINITION_FAMILY=$4
IMAGE_URI=$5

echo "Updating ECS task definition..."

# Get the current task definition
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition ${TASK_DEFINITION_FAMILY} --region ${AWS_REGION})

# Update the image URI in the task definition
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE_URI "$IMAGE_URI" '.taskDefinition | .containerDefinitions[0].image = $IMAGE_URI | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.placementConstraints) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')

# Register the new task definition
NEW_TASK_INFO=$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json "$NEW_TASK_DEFINITION")

NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')

echo "New task definition revision: ${NEW_REVISION}"

# Update the service
echo "Updating ECS service..."
aws ecs update-service --region ${AWS_REGION} --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_DEFINITION_FAMILY}:${NEW_REVISION}

echo "Waiting for deployment to complete..."
aws ecs wait services-stable --region ${AWS_REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}

echo "Deployment completed successfully!"