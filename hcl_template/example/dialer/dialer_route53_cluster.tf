resource "aws_route53_record" "asterisk_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-asterisk.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.asterisk.private_ip]
}

resource "aws_route53_record" "omlapp_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-omlapp.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.omlapp.private_ip]
}

resource "aws_route53_record" "redis_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-redis.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.redis.private_ip]
}

resource "aws_route53_record" "dialer_dns" {
  zone_id     = data.aws_route53_zone.selected.zone_id
  name        = "${var.customer}-dialer.${var.domain_name}"
  type        = "A"
  ttl         = "180"
  records     = [aws_instance.dialer_ec2.private_ip]
}
