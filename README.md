# marqo-base
The dependencies and Dockerfile for creating the Marqo base image  

## Pull an ECR image

```
# 1. Authenticate into the ECR repo
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 424082663841.dkr.ecr.us-east-1.amazonaws.com
# 2. Pull your tag
docker pull 424082663841.dkr.ecr.us-east-1.amazonaws.com/marqo:my-tag
```
