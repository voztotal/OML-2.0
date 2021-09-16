#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
DOCKER=$(which docker)
printf "$GREEN** [OMniLeads] ************************************** $NC\n"
printf "$GREEN** [OMniLeads] Script to run terraform using Docker * $NC\n"
printf "$GREEN** [OMniLeads] ************************************** $NC\n"
if [ -z $DOCKER ]; then
  printf "$RED** [OMniLeads] Docker was not found, please install it $NC\n"
fi
printf "$GREEN** [OMniLeads] Pulling the latest image of terraform $NC\n"
docker pull freetechsolutions/terraform:latest

printf "$GREEN** [OMniLeads] Run and exec the container $NC\n"
docker run -it --rm --name terraform \
  --mount type=bind,source="$(pwd)",target=/home/terraform/src \
  --mount type=bind,source="/home/$(whoami)/.ssh",target=/home/terraform/.ssh \
  --env-file .env \
  --network=host \
  --workdir=/home/terraform/src \
  freetechsolutions/terraform:latest bash
