#!/bin/bash

set -e

AWS_DEFAULT_REGION="eu-central-1"
TASK_FAMILY="demo-app-task"
ECR_IMAGE="632296647497.dkr.ecr.eu-central-1.amazonaws.com/demo-app:latest"

CURRENT_TASK=$(aws ecs describe-task-definition --task-definition "${TASK_FAMILY}" --region "${AWS_DEFAULT_REGION}")

NEW_TASK=$(echo $CURRENT_TASK | jq --arg IMAGE "${ECR_IMAGE}" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')

aws ecs register-task-definition --region "${AWS_DEFAULT_REGION}" --cli-input-json "$NEW_TASK"
