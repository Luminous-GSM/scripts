#!/bin/bash

#=====> Install requirements <=====#
yum update -y
amazon-linux-extras install docker
systemctl start docker
systemctl enable --now docker

usermod -a -G docker ec2-user
chmod 666 /var/run/docker.sock

# Replace the ExecStart with the one below
SEARCH_STRING=".*ExecStart=/usr/bin/dockerd.*"
REPLACE_STRING="ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"
FILE_DIRECTORY="/usr/lib/systemd/system/docker.service"
sed -i "s,${SEARCH_STRING},${REPLACE_STRING}," ${FILE_DIRECTORY}

systemctl daemon-reload
systemctl restart docker

#=====> CONSTANTS <=====#
PORT=7878
POD_NAME="fusion-agent"
AGENT_VERSION="0.0.1-SNAPSHOT"
DOCKER_IMAGE="ghcr.io/luminous-gsm/fusion:${AGENT_VERSION}"
MEMORY_ALLOCATION="256m"
RESTART_POLICY="always"

#=====> VARIABLES <=====#
paramters=("$@")
ENV_NODE_NAME=${paramters[0]}
ENV_NODE_UNIQUE_ID=${paramters[1]}
ENV_NODE_DESCRIPTION=${paramters[2]}
ENV_NODE_AUTHORIZATION_TOKEN=${paramters[3]}
ENV_PLATFORM=${paramters[4]}
ENV_NODE_HOSTNAME=${paramters[5]}

# Get the hostname of the EC2 instance
if [ "$ENV_PLATFORM" == "aws" ]; then
  ENV_NODE_HOSTNAME="$(ec2-metadata --local-hostname | cut -d " " -f 2)"
fi

#=====> AGENT RUN COMMAND <=====#
docker pull "${DOCKER_IMAGE}"
if [[ $(docker ps -a --filter="name=${POD_NAME}" --filter "status=exited" | grep -w "${POD_NAME}") ]]; then
  echo "Fusion Agent should be starting automatically"
  docker rm "${POD_NAME}"
elif [[ $(docker ps -a --filter="name=${POD_NAME}" --filter "status=running" | grep -w "${POD_NAME}") ]]; then
  echo "Fusion Agent running"
  docker stop "${POD_NAME}"
  docker rm "${POD_NAME}"
fi

docker create -m ${MEMORY_ALLOCATION} -v /var/run/docker.sock:/var/run/docker.sock -e ENV_NODE_NAME="${ENV_NODE_NAME}" -e ENV_NODE_UNIQUE_ID="${ENV_NODE_UNIQUE_ID}" -e ENV_NODE_DESCRIPTION="${ENV_NODE_DESCRIPTION}" -e ENV_NODE_AUTHORIZATION_TOKEN="${ENV_NODE_AUTHORIZATION_TOKEN}" -e ENV_PLATFORM="${ENV_PLATFORM}" -e ENV_NODE_HOSTNAME="${ENV_NODE_HOSTNAME}" -p ${PORT}:${PORT} --name ${POD_NAME} --restart "${RESTART_POLICY}" ${DOCKER_IMAGE}
docker start -a "${POD_NAME}"