.PHONY: all

DEFAULT_TARGET: all

TF_BIN ?= terraform
AWS_REGION ?= ${AWS_REGION}

# AWS_SDK_LOAD_CONFIG: to be able to use shared credentials. Refer to:
# https://docs.aws.amazon.com/sdk-for-go/api/aws/session/
TF_VARS = cd instances/$(TENANT) && AWS_SDK_LOAD_CONFIG=1 ARQ=$(ARQ) DIALER=$(DIALER)

TF_ARGS = $(TARGET)

check-env:
  ifndef TENANT
    $(error TENANT is undefined. Use 'TENANT=<env>' <env> is any directory under /instances)
  endif

all: init plan

get:
	utils/aws_utils.sh get_common_modules $(TENANT)
	$(TF_VARS) $(TF_BIN) get

plan:
	$(TF_VARS) $(TF_BIN) plan $(TF_ARGS)

apply:
	$(TF_VARS) $(TF_BIN) apply $(TF_ARGS)

refresh:
	$(TF_VARS) $(TF_BIN) refresh $(TF_ARGS)

destroy:
	$(TF_VARS) $(TF_BIN) destroy $(TF_ARGS)

retrieve_installers:
	utils/aws_utils.sh retrieve_oml_installers $(BRANCH)

clean:
	rake remove_modules[$(TENANT)]
	utils/aws_utils.sh undo_links $(TENANT)

prereqs:
	test -d instances/$(TENANT)
	aws --version
	rake --version
	$(TF_BIN) -version

init:
	utils/aws_utils.sh prepare_deploy_links $(TENANT) $(ARQ) $(DIALER)
	make get
	utils/aws_utils.sh write_backend_s3 $(TENANT)
	utils/aws_utils.sh create_s3_backend $(TENANT)
	$(TF_VARS) $(TF_BIN) init $(TF_ARGS)

errored:
	$(TF_VARS) $(TF_BIN) state push errored.tfstate

show:
	$(TF_VARS) $(TF_BIN) show

output:
	$(TF_VARS) $(TF_BIN) output $(OUTPUT)

import:
	$(TF_VARS) $(TF_BIN) import $(RESOURCE_NAME) $(RESOURCE_ID)

upload:
	utils/aws_utils.sh write_backend_s3 $(TENANT)
	$(TF_VARS) $(TF_BIN) init
