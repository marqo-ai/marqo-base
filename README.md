# marqo-base
The dependencies and Dockerfile for creating the Marqo base image  

The marqo-base image is an image that has the necessary dependencies for the Maroq to be installed on and run. This speeds up the build process. 

## Pull an ECR image

```
# 1. Authenticate into the ECR repo
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 424082663841.dkr.ecr.us-east-1.amazonaws.com
# 2. Pull your tag
docker pull 424082663841.dkr.ecr.us-east-1.amazonaws.com/marqo-base:my-tag
```
