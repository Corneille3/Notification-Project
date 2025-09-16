locals {
  # Handy ARNs / names
  ecs_cluster_name = aws_ecs_cluster.main.name
  lb_suffix        = aws_lb.internal.arn_suffix
  tg_suffixes      = { for k, tg in aws_lb_target_group.tg : k => tg.arn_suffix }
  api_id           = aws_apigatewayv2_api.internal.id
  stage_name       = aws_apigatewayv2_stage.prod.name # "$default" or "prod"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "notification-project-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # ============= ECS (cluster) =============
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 0, "y" : 0,
        "properties" : {
          "region" : var.aws_region,
          "title" : "ECS Cluster CPU & Memory",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.ecs_cluster_name, { "stat" : "Average", "label" : "CPU % (cluster)" }],
            [".", "MemoryUtilization", "ClusterName", local.ecs_cluster_name, { "stat" : "Average", "label" : "Mem % (cluster)" }]
          ],
          "period" : 300
        }
      },

      # ============= ECS (services) =============
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 12, "y" : 0,
        "properties" : {
          "region" : var.aws_region,
          "title" : "ECS Services CPU/Memory",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.requestor.name, { "label" : "Requestor CPU %" }],
            [".", "MemoryUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.requestor.name, { "label" : "Requestor Mem %" }],
            [".", "CPUUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.worker.name, { "label" : "Worker CPU %" }],
            [".", "MemoryUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.worker.name, { "label" : "Worker Mem %" }],
            [".", "CPUUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.administrator.name, { "label" : "Admin CPU %" }],
            [".", "MemoryUtilization", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.administrator.name, { "label" : "Admin Mem %" }]
          ],
          "period" : 300
        }
      },
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 0, "y" : 6,
        "properties" : {
          "region" : var.aws_region,
          "title" : "ECS Running Tasks",
          "view" : "timeSeries",
          "metrics" : [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.requestor.name, { "stat" : "Average", "label" : "Requestor" }],
            [".", "RunningTaskCount", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.worker.name, { "stat" : "Average", "label" : "Worker" }],
            [".", "RunningTaskCount", "ClusterName", local.ecs_cluster_name, "ServiceName", aws_ecs_service.administrator.name, { "stat" : "Average", "label" : "Admin" }]
          ],
          "period" : 300
        }
      },

      # ============= ALB overview =============
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 12, "y" : 6,
        "properties" : {
          "region" : var.aws_region,
          "title" : "ALB Requests & Errors",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.lb_suffix, { "stat" : "Sum", "label" : "Requests" }],
            [".", "HTTPCode_ELB_4XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum", "label" : "ELB 4xx" }],
            [".", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum", "label" : "ELB 5xx" }],
            [".", "HTTPCode_Target_4XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum", "label" : "Target 4xx" }],
            [".", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.lb_suffix, { "stat" : "Sum", "label" : "Target 5xx" }],
            [".", "TargetResponseTime", "LoadBalancer", local.lb_suffix, { "stat" : "Average", "label" : "Target RTT (avg)" }]
          ],
          "period" : 300
        }
      },

      # ============= ALB Healthy targets per TG =============
      {
        "type" : "metric",
        "width" : 24, "height" : 6, "x" : 0, "y" : 12,
        "properties" : {
          "region" : var.aws_region,
          "title" : "ALB Healthy Targets per TG",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", local.tg_suffixes.Requestor, "LoadBalancer", local.lb_suffix, { "label" : "Requestor" }],
            [".", "HealthyHostCount", "TargetGroup", local.tg_suffixes.Worker, "LoadBalancer", local.lb_suffix, { "label" : "Worker" }],
            [".", "HealthyHostCount", "TargetGroup", local.tg_suffixes.Administrator, "LoadBalancer", local.lb_suffix, { "label" : "Admin" }]
          ],
          "period" : 60
        }
      },

      # ============= API Gateway (HTTP API) =============
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 0, "y" : 18,
        "properties" : {
          "region" : var.aws_region,
          "title" : "API Gateway: Requests & Errors",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ApiGateway", "Count", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "Sum", "label" : "Requests" }],
            [".", "4xx", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "Sum", "label" : "4xx" }],
            [".", "5xx", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "Sum", "label" : "5xx" }]
          ],
          "period" : 300
        }
      },
      {
        "type" : "metric",
        "width" : 12, "height" : 6, "x" : 12, "y" : 18,
        "properties" : {
          "region" : var.aws_region,
          "title" : "API Gateway: Latency",
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/ApiGateway", "Latency", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "p50", "label" : "p50" }],
            [".", "Latency", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "p90", "label" : "p90" }],
            [".", "Latency", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "p99", "label" : "p99" }],
            [".", "IntegrationLatency", "ApiId", local.api_id, "Stage", local.stage_name, { "stat" : "Average", "label" : "IntegrationLatency avg" }]
          ],
          "period" : 300
        }
      }
    ]
  })
}
