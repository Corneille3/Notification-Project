variable "ecs_task_execution_role_name" {
  type        = string
  default     = "ecsTaskExecutionRole"
  description = "Name of the ECS task execution role"
}

data "aws_iam_policy_document" "ecs_task_execution_assume" {

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_user" "ecr_push_user" {
  name = "ecr-push-user"
}

resource "aws_iam_user_policy_attachment" "ecr_push_policy" {
  user       = aws_iam_user.ecr_push_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

