output "acm_arn" {
  value = module.acm_certificate.cert_arn
}

output "private_cidr_blocks" {
  value = module.networking.private_subnets_cidr_blocks
}

output "vpc_cidr_block" {
  value = module.networking.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "rtpengine_fqdn" {
  value = aws_route53_record.rtpengine.fqdn
}

output "sg_rds_id" {
  value = aws_security_group.rds_sg.id
}

output "sg_astsbc_id" {
  value = aws_security_group.astsbc_ec2_sg.id
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "ec2_key" {
  value = aws_key_pair.ec2.key_name
}
#output "all_states" {
#  value = data.terraform_remote_state.shared_state.*
#}
