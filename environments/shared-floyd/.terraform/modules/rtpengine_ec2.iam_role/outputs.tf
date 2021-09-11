output "role_id" {
  value       = aws_iam_role.iam_role.id
  description = "The name of the role."
}

output "role_arn" {
  value       = aws_iam_role.iam_role.arn
  description = "The Amazon Resource Name (ARN) specifying the role."
}

output "role_unique_id" {
  value       = aws_iam_role.iam_role.unique_id
  description = "The stable and unique string identifying the role."
}

output "role_name" {
  value       = aws_iam_role.iam_role.name
  description = "The name of the role."
}

output "role_description" {
  value       = aws_iam_role.iam_role.description
  description = "The description of the role."
}

output "role_create_date" {
  value       = aws_iam_role.iam_role.create_date
  description = "The creation date of the IAM role."
}