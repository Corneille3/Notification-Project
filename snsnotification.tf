/*############################################
# SNS: Alerting
############################################
variable "alert_email" {
  description = "Email to subscribe for CloudWatch alarms (leave blank to skip subscription)"
  type        = string
  default     = ""
}

resource "aws_sns_topic" "alerts" {
  name = "notification-project-alerts"
}

# Optional email subscription (only created when alert_email is non-empty)
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "alerts_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic ARN for alarms"
}

############################################
# Locals
############################################
locals {
  ecs_cluster_name = aws_ecs_cluster.main.name
  lb_suffix        = aws_lb.internal.arn_suffix
  api_id           = aws_apigatewayv2_api.internal.id
  stage_name       = aws_apigatewayv2_stage.prod.name  # "$default" or "prod"

  ecs_services = {
    Requestor     = aws_ecs_service.requestor.name
    Worker        = aws_ecs_service.worker.name
    Administrator = aws_ecs_service.administrator.name
  }
}

############################################
# ALB 5xx spike (per Load Balancer)
############################################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "ALB-5xx-High"
  alarm_description   = "ALB 5xx count elevated over the last 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions          = { LoadBalancer = local.lb_suffix }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

############################################
# API Gateway 5xx spike (HTTP API)
############################################
resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "APIGW-5xx-High"
  alarm_description   = "API Gateway 5xx responses elevated over the last 5 minutes"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  dimensions          = { ApiId = local.api_id, Stage = local.stage_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

############################################
# ECS Service CPU > 70% (per service)
############################################
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each            = local.ecs_services
  alarm_name          = "ECS-CPU-High-${each.key}"
  alarm_description   = "ECS service CPU > 70% for 10 minutes"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = {
    ClusterName = local.ecs_cluster_name
    ServiceName = each.value
  }
  statistic           = "Average"
  period              = 120
  evaluation_periods  = 5
  threshold           = 70
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

############################################
# ECS Running tasks < desired (basic availability)
############################################
resource "aws_cloudwatch_metric_alarm" "ecs_running_low" {
  for_each            = local.ecs_services
  alarm_name          = "ECS-RunningTasks-Low-${each.key}"
  alarm_description   = "ECS service running tasks below desired count"
  namespace           = "AWS/ECS"
  metric_name         = "RunningTaskCount"
  dimensions          = {
    ClusterName = local.ecs_cluster_name
    ServiceName = each.value
  }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0.9
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
*/