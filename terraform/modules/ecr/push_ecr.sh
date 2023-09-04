#!/bin/sh
aws ecr get-login-password --profile ${AWS_PROFILE} --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker tag ${LOCAL_IMAGE_NAME}:${LOCAL_IMAGE_TAG} ${ECR_URI}
docker push ${ECR_URI}