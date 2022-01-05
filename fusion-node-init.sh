#!/bin/bash

#=====> Install requirements <=====#
yum update -y
amazon-linux-extras install docker
service docker start
systemctl enable --now docker

usermod -a -G docker ec2-user
chmod 666 /var/run/docker.sock

#=====> CONSTANTS <=====#
PORT=7878
POD_NAME="fusion-agent"
DOCKER_IMAGE="ghcr.io/luminous-gsm/fusion:latest"

#=====> VARIABLES <=====#
paramters=("$@")
ENV_NODE_NAME=${paramters[0]}
ENV_NODE_UNIQUE_ID=${paramters[1]}
ENV_NODE_DESCRIPTION=${paramters[2]}
ENV_NODE_AUTHORIZATION_TOKEN=${paramters[3]}
ENV_PLATFORM=${paramters[4]}

#=====> AGENT RUN COMMAND <=====#
docker run -v /var/run/docker.sock:/var/run/docker.sock -e ENV_NODE_NAME="${ENV_NODE_NAME}" -e ENV_NODE_UNIQUE_ID="${ENV_NODE_UNIQUE_ID}" -e ENV_NODE_DESCRIPTION="${ENV_NODE_DESCRIPTION}" -e ENV_NODE_AUTHORIZATION_TOKEN="${ENV_NODE_AUTHORIZATION_TOKEN}" -e ENV_PLATFORM="${ENV_PLATFORM}" -p ${PORT}:${PORT} --name ${POD_NAME} ${DOCKER_IMAGE}
