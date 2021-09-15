############################### iam for SSM ################################
resource "aws_iam_role" "test_role" {
  name = "${var.customer}-iamrole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.customer}-test-policy"
  description = "A test policy"
  policy      = file("${path.module}/templates/ec2_ssm_policy.tpl") 
}

resource "aws_iam_policy" "policy_s3" {
  name        = "${var.customer}-test-policy-s3"
  description = "A test policy S3"
  policy      = templatefile("${path.module}/templates/s3_full_access_policy.tpl", {
    astsbc_s3_bucket = aws_s3_bucket.customer_data.arn
  }) 
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.test_role.name]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_policy_attachment" "s3-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.test_role.name]
  policy_arn = aws_iam_policy.policy_s3.arn
}

resource "aws_iam_instance_profile" "test_profile" {
  name  = "${var.customer}-test_profile"
  roles = [aws_iam_role.test_role.name]
}

resource "aws_iam_role_policy" "ec2_ssm_management" {
  name   = "${var.customer}-SsmManagement"
  role   = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

############################### iam for S3 ################################

resource "aws_iam_role_policy" "ec2_s3_access_management" {
  name = "${var.customer}S3FullAccessManagement"
  role = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/s3_full_access_policy.tpl", {
    astsbc_s3_bucket = aws_s3_bucket.customer_data.arn
  })
}

############################### iam for EBS ################################

resource "aws_iam_role_policy" "ec2_ebs_attach_management" {
  name   = "${var.customer}EbsAttachManagement"
  role   = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ebs_attach_policy.tpl", {})
}