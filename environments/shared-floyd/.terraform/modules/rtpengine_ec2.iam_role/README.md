# tf-aws-iam-role-common

## Overview:

Creates a standard, non-specific IAM role with Describe and CreateTags permissions.

## Usage:
```
module "my-iam-role" {
  source        = "../modules/tf-aws-iam-role-common"
  iam_role_name = my-iam-role-name
}
```

## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| iam_role_name | Your IAM Role Name | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| role_id | IAM Role ID |
| role_arn | IAM Role ARN |
| role_unique_id | IAM Role Unique ID |
| role_name | The name of the role. |
| role_description | The description of the role. |
| role_create_date | The creation date of the IAM role. |
