#Create an ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Internal-ALB-SG"
  vpc_id      = aws_vpc.main.id
}

# ALB: ingress only from API GW VPC Link on HTTP:80
resource "aws_vpc_security_group_ingress_rule" "alb_from_vpclink_http" {
  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.vpc_link_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "API-GW-VPC-Link-to-ALB-(HTTP)"
}

# ALB egress to ECS on each backend port
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs_per_backend" {
  for_each                     = local.backends
  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ecs_tasks_sg.id
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  description                  = "ALB-to-ECS-${each.key}-over-HTTP"
}

# ECS tasks SG
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "ECS-tasks-SG"
  vpc_id      = aws_vpc.main.id
}

# ECS ingress from ALB per backend port
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb_per_backend" {
  for_each                     = local.backends
  security_group_id            = aws_security_group.ecs_tasks_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  description                  = "ECS-${each.key}-from-ALB-over-HTTP"
}

# ECS egress HTTPS (via NAT)
resource "aws_vpc_security_group_egress_rule" "ecs_https_out" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "ECS-tasks-Internet-over-HTTPS-(via-NAT)"
}

# API Gateway VPC Link SG
resource "aws_security_group" "vpc_link_sg" {
  name        = "apigw-vpc-link-sg"
  description = "API-Gateway-VPC-Link-ENIs"
  vpc_id      = aws_vpc.main.id
}

# VPC Link egress to ALB :80
resource "aws_vpc_security_group_egress_rule" "vpclink_to_alb_http" {
  security_group_id            = aws_security_group.vpc_link_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "VPC-Link-to-ALB-(HTTP)"
}
