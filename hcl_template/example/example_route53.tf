resource "aws_route53_record" "asterisk_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-asterisk.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.asterisk.private_ip]
}

# resource "aws_route53_record" "observability_dns" {
#   zone_id     = data.aws_route53_zone.selected.zone_id
#   name        = "${var.customer}-observability.${var.domain_name}"
#   type        = "A"
#   ttl         = "180"
#   records     = [aws_instance.observability.private_ip]
# }

# resource "aws_route53_record" "observability_public_dns" {
#   zone_id     = data.aws_route53_zone.selected.zone_id
#   name        = "${var.customer}-prometheus.${var.domain_name}"
#   type        = "A"
#   ttl         = "180"
#   records     = [aws_instance.observability.public_ip]
# }

resource "aws_route53_record" "redis_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-redis.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.redis.private_ip]
}
