resource "aws_lb" "internal" {
  name               = "app-internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  for_each    = local.backends
  name        = "tg-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {

    path                = each.value.health_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5

    /*# Use "/" just for Worker; keep others as defined
    path                = each.key == "Worker" ? "/" : each.value.health_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5*/


  }

  lifecycle { create_before_destroy = true }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  # deny unmatched hosts
  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "400"
      content_type = "application/json"
      message_body = "{\"error\":\"Bad Request\"}"
    }
  }
}

resource "aws_lb_listener_rule" "host_rules" {
  for_each     = local.backends
  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    host_header { values = each.value.hostnames }
  }
}
