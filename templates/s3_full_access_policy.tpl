{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "${astsbc_s3_bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "${astsbc_s3_bucket}"
    }
  ]
}
