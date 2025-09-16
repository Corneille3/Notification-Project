# Cluster
resource "aws_ecs_cluster" "main" {
  name = "internal-app-cluster"
}

# Logs (enable if you want)
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/internal-app"
  retention_in_days = 14
}

# Container image variables
variable "requestor_image" {
  type    = string
  default = "515275664907.dkr.ecr.us-east-1.amazonaws.com/requestor-web:v1"
}
variable "worker_image" {
  type    = string
  default = "515275664907.dkr.ecr.us-east-1.amazonaws.com/worker:v2"
}
variable "administrator_image" {
  type    = string
  default = "your-account-id.dkr.ecr.us-east-1.amazonaws.com/administrator:latest"
}

# Task defs (FINAL SOURCE OF TRUTH)
resource "aws_ecs_task_definition" "Requestor" {
  family                   = "Requestor-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name         = "Requestor"
    image        = var.requestor_image
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "requestor"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "Worker" {
  family                   = "Worker-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name         = "Worker" # renamed from "api"
    image        = var.worker_image
    essential    = true
    portMappings = [{ containerPort = 9090, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "worker"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "Administrator" {
  family                   = "Administrator-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name         = "Administrator"
    image        = var.administrator_image
    essential    = true
    portMappings = [{ containerPort = 7070, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "administrator"
      }
    }
  }])
}

# Services (match container_name exactly)
resource "aws_ecs_service" "requestor" {
  name                 = "requestor-svc"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.Requestor.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg["Requestor"].arn
    container_name   = "Requestor"
    container_port   = 8080
  }

  lifecycle { ignore_changes = [task_definition] }
}

resource "aws_ecs_service" "worker" {
  name                 = "worker-svc"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.Worker.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg["Worker"].arn
    container_name   = "Worker"
    container_port   = 9090
  }

  lifecycle { ignore_changes = [task_definition] }
}

resource "aws_ecs_service" "administrator" {
  name                 = "administrator-svc"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.Administrator.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg["Administrator"].arn
    container_name   = "Administrator"
    container_port   = 7070
  }

  lifecycle { ignore_changes = [task_definition] }
}
