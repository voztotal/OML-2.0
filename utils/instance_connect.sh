#!/bin/bash

set -eo pipefail
PATH=$PATH:~/.local/bin
ENVS_DIR=environments
AWS="/usr/local/bin/aws"
INSTANCE=$1
INSTANCE_ID=$($AWS ec2 describe-instances \
                --filters "Name=tag:Name,Values=*-$INSTANCE-EC2*" 'Name=instance-state-code,Values=16'  \
                --output text \
                --query 'Reservations[].Instances[].InstanceId')
if [ -z "$INSTANCE_ID" ]; then
  echo "No hay instancias de $INSTANCE disponibles, saliendo"; exit 1
else
  $AWS ssm start-session --target $INSTANCE_ID
fi
