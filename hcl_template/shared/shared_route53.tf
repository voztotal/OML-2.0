data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}"
}

resource "aws_route53_record" "rtpengine" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "rtpengine-${var.customer}.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.rtpengine_eip.public_ip]
}

resource "aws_route53_record" "astsbc" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "astsbc-${var.customer}.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.astsbc_eip.public_ip]
}

resource "aws_route53_record" "astsbc_internal" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "astsbc-internal-${var.customer}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.astsbc_int_sip_nlb.nlb_dns_name
    zone_id                = module.astsbc_int_sip_nlb.nlb_zone_id
    evaluate_target_health = true
  }
}
