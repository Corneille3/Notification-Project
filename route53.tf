resource "aws_route53_zone" "internal" {
  name = "internal.local"
  vpc { vpc_id = aws_vpc.main.id }
  comment = "Private zone for internal ALB"
}

resource "aws_route53_record" "alb_alias" {
  for_each = toset(local.hosts)
  zone_id  = aws_route53_zone.internal.zone_id
  name     = "${each.key}.internal.local"
  type     = "A"
  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = false
  }
}
