data "template_file" "aws_iam_role_tpl" {
  template = file("${path.module}/templates/aws_iam_role.tpl")
}

data "template_file" "aws_iam_role_policy_tpl" {
  template = file("${path.module}/templates/aws_iam_role_policy.tpl")
}

resource "aws_iam_role" "iam_role" {
  name_prefix        = "${var.iam_role_name}-"
  assume_role_policy = data.template_file.aws_iam_role_tpl.rendered
}

resource "aws_iam_role_policy" "ec2_describe_tags" {
  name   = "ec2DescribeTags"
  role   = aws_iam_role.iam_role.id
  policy = data.template_file.aws_iam_role_policy_tpl.rendered
}
