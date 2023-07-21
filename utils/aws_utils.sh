#!/bin/bash

set -eo pipefail
PATH=$PATH:~/.local/bin
ENVS_DIR=instances
AWS="/usr/local/bin/aws"
PTERRAFILE="/usr/local/bin/pterrafile"

if [ -z "${1}" ]; then
  echo "Usage:"
  echo -e "\t> ./aws_utils.sh prepare_deploy_links <environment>"
fi

prepare_deploy_links() {
  
  local environment=$1
  local arq=$2
  local dialer=$3
  
  if [ ! -d ${ENVS_DIR}/${environment} ]; then
    mkdir -p ${ENVS_DIR}/${environment}
  fi
  undo_links ${environment}
  cd ${ENVS_DIR}/${environment}/
  if [[ ${environment} == *"shared"* ]]; then
    ln -s ../../hcl_template/shared/*.tf .
    ln -s ../../hcl_template/shared/Terrafile .
    if [ -f ${environment}.auto.tfvars ]; then
      cp ${environment}.auto.tfvars ${environment}.auto.tfvars.backup
      cp ${environment}.auto.tfvars.backup ${environment}.auto.tfvars
    else
      ln -s ../../hcl_template/shared/shared.auto.tfvars .
    fi
    find . -name 'shared_*' -exec bash -c 'mv $0 ${0/shared/'"${environment}"'}' {} \;
    find . -name 'shared.*' -exec bash -c 'mv $0 ${0/shared/'"${environment}"'}' {} \;
    sed -i "s/changemeplease/${environment}/g" ${environment}.auto.tfvars
  elif [[ ${arq} == *"cluster"* ]]; then
    ln -s ../../hcl_template/example/*.tf .
    ln -s ../../hcl_template/example/Terrafile .
    rm -rf example_ec2_aio.tf
  elif [[ ${arq} == *"aio"* ]]; then
    ln -s ../../hcl_template/example/*.tf .
    ln -s ../../hcl_template/example/Terrafile .
    rm -rf example_ec2_cluster.tf
    rm -rf example_ec2_asterisk.tf
    rm -rf example_route53.tf
  else
    echo "ERROR: You must to pass the ARQ parameter"
  fi
  if [ -f ${environment}.auto.tfvars ]; then
      cp ${environment}.auto.tfvars ${environment}.auto.tfvars.backup
      cp ../../hcl_template/example/example.auto.tfvars ${environment}.auto.tfvars
  else
    ln -s ../../hcl_template/example/example.auto.tfvars .
  fi  
  find . -name 'example_*' -exec bash -c 'mv $0 ${0/example/'"${environment}"'}' {} \;
  find . -name 'example.*' -exec bash -c 'mv $0 ${0/example/'"${environment}"'}' {} \;
  echo "Editing ${environment}_backend.tf and customer variable in ${environment}.auto.tfvars"
  sed -i "s/example/${environment}/g" ${environment}.auto.tfvars
  if [ "${dialer}" == "yes" ] || [ "${dialer}" == "YES" ]; then
    ln -s ../../hcl_template/example/dialer/*.tf .
    rm -rf ${environment}_locals.tf
  elif [ "${dialer}" == "no" ] || [ "${dialer}" == "NO" ]; then
    rm -rf dialer*
    if [ ! -f ${environment}_locals.tf ]; then ln -s ../../hcl_template/example/example_locals.tf ./${environment}_locals.tf; fi
  elif [ "${dialer}" == "" ]; then
    echo "DIALER envar wasn't passed"; exit 1
  else
    echo "Invalid option for DIALER envar, valid options YES/yes or NO/no"; exit 1
  fi
  ln -s ../../common/*.tf .
  sed -i "s/sharedus/${TF_VAR_shared_env}/" ./${environment}.auto.tfvars

  if [[ ${environment} == *"shared"* ]]; then
    rm -rf common_remote_state.tf
  fi
  #ln -s ../../keys .
  ln -s ../../templates/ .
  if [ -f "./.reusables" ]; then
    for tf in $(cat ./.reusables); do
        ln -s ../../reusables/$tf .
    done
  fi
}

write_backend_s3() {
  local environment=$1
  cd ${ENVS_DIR}/${environment}/
  rm -rf ${environment}_backend.tf
  echo "Modifying ${environment}_backend.tf file"
  cat > ${environment}_backend.tf <<EOF
terraform {
  required_version = "~> 0.12.9"
  backend "s3" {
    bucket  = "terraform-${environment}-${TF_VAR_owner}-project-prod-tfstate"
    key     = "terraform.tfstate"
    region  = "${AWS_DEFAULT_REGION}"
    encrypt = "true"
  }
}
EOF
}

create_s3_backend() {
  local environment=$1
  if [ $AWS_DEFAULT_REGION == "us-east-1" ]; then
    echo "us-east-1 region"
    OPTIONS=""
  else
    OPTIONS="--create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION"
  fi
  cd ${ENVS_DIR}/${environment}/
  BUCKET_NAME=$(grep -R "bucket" ${environment}_backend.tf |awk -F "=" '{print $2}'| tr -d '"' |tr -d ' ')
  echo "Checking if bucket $BUCKET_NAME exists in s3"
  BUCKET_S3=$($AWS s3 ls |grep "terraform-$environment-" |awk -F " " '{print $3}'|| true)
  if [ -z "${BUCKET_S3}" ]; then
    echo "Creating s3 bucket $BUCKET_NAME"
    $AWS s3api create-bucket --bucket $BUCKET_NAME \
      --region $AWS_DEFAULT_REGION $OPTIONS
  else
    echo "$BUCKET_S3 bucket already exists"
  fi
}

delete_s3_bucket() {
  local environment=$1
  echo "Getting bucket to delete its objects"
  BUCKET=$($AWS s3 ls |grep "\-$environment-" |awk -F ' ' '{print $3}')
  $AWS s3 rb s3://$BUCKET --force
}

get_common_modules() {
    local environment=$1
    cd ${ENVS_DIR}/${environment}/
    MODULES_LOCATION="${ENVS_DIR}/${environment}/modules"
    if [ ! -d modules ]; then
      mkdir modules
    fi
    cp Terrafile modules/
    $PTERRAFILE modules
}

del_common_modules() {
  local environment=$1
  rm -rf ${ENVS_DIR}/${environment}/modules
  rm -rf ${ENVS_DIR}/${environment}
}

undo_links() {
  links=$(find ${ENVS_DIR}/${1} -type l -path "${ENVS_DIR}/${1}/.terraform/*" -prune -o -type l -print)
  echo $links
  for file in ${links}; do
    unlink ${file}
  done
}

retrieve_oml_installers() {
  local branch=$1
  if [ ! -d oml_installers ]; then
    mkdir -p oml_installers
  fi
  curl https://gitlab.com/omnileads/ominicontacto/-/raw/${1}/install/onpremise/deploy/ansible/first_boot_installer.tpl?inline=false > oml_installers/omlapp.tpl
  curl https://gitlab.com/omnileads/omlredis/-/raw/${1}/deploy/first_boot_installer.tpl?inline=false > oml_installers/first_boot_installer.tpl
  curl https://gitlab.com/omnileads/omlacd/-/raw/${1}/deploy/first_boot_installer.tpl?inline=false > oml_installers/first_boot_installer.tpl
  curl https://gitlab.com/omnileads/omlkamailio/-/raw/${1}/deploy/first_boot_installer.tpl?inline=false > oml_installers/first_boot_installer.tpl
}

$@
