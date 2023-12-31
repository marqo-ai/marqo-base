# marqo-base
The dependencies and Dockerfile for creating the Marqo base image  

The marqo-base image is an image that has the necessary dependencies for the Marqo to be installed on and run. This speeds up the build process. 

## Build and push a new Marqo-base version to Dockerhub
To release a new version of Marqo-base to Dockerhub:

1. run the [push-to-dockerhub](https://github.com/marqo-ai/marqo-base/actions/workflows/push_to_dockerhub.yml) workflow with default options. By default, an always-increasing integer will be used as the image tag. The resulting image tag won't necessarily be the `previous_tag + 1`, as the GitHub run number is used, which also increments on failed runs. If you want to use a different tag, such as "test" you can set it as the second param.
<img width="800" alt="image" src="https://github.com/marqo-ai/marqo-base/assets/107458762/29b367a2-37a2-4cbf-b7a9-3e116d925d2b">

2. You will get a message during one of the steps to review deployments before the image is built and pushed to dockerhub:
<img width="800" alt="image" src="https://github.com/marqo-ai/marqo-base/assets/107458762/70d3fee8-f696-48d5-bd59-5198c5210bdf">

Please don't forget about this pipeline when there is a pending review because the ec2 instance used to build the image will still be running until the deployment is approved or the workflow is cancelled. If you are an authorised reviewer, click approve and deploy:
<img width="800" alt="image" src="https://github.com/marqo-ai/marqo-base/assets/107458762/be39b114-6fac-48a0-a010-7f8400515f5d">

4. The workflow will proceed to push a new version to Dockerhub! If you want to confirm the name of the new marqo-base image that was generated, you can download this artefact.
<img width="800" alt="image" src="https://github.com/marqo-ai/marqo-base/assets/107458762/c26def93-7307-4b45-a1fa-152fc1c48c52">
<img width="214" alt="image" src="https://github.com/marqo-ai/marqo-base/assets/107458762/c1c6b799-ce6c-4e04-a3e0-afb166a126d5">


## Pull an ECR image

```
# 1. Authenticate into the ECR repo
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 424082663841.dkr.ecr.us-east-1.amazonaws.com
# 2. Pull your tag
docker pull 424082663841.dkr.ecr.us-east-1.amazonaws.com/marqo-base:my-tag
```
