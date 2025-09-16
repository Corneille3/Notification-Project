variable "ecr_repo_name_consumer" {
  description = "Notification repo images"
  type        = string
  default     = "requestor-web"
}
variable "kms_key_arn" {
  description = "KMS key ARN for ECR encryption"
  type        = string
  default     = ""
}

resource "aws_ecr_repository" "consumer_repo" {
  name                 = var.ecr_repo_name_consumer
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }

  encryption_configuration {
    encryption_type = var.kms_key_arn == "" ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn == "" ? null : var.kms_key_arn
  }
  tags = { Name = var.ecr_repo_name_consumer }
}

resource "aws_ecr_lifecycle_policy" "clean" {
  repository = aws_ecr_repository.consumer_repo.name
  policy     = <<JSON
{ "rules": [
  { "rulePriority": 1, "description": "Expire untagged >14d",
    "selection": { "tagStatus": "untagged", "countType": "sinceImagePushed", "countUnit": "days", "countNumber": 14 },
    "action": { "type": "expire" } },
  { "rulePriority": 2, "description": "Keep last 30 images",
    "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 30 },
    "action": { "type": "expire" } }
]}
JSON
}

output "repository_name" { value = aws_ecr_repository.consumer_repo.name }
output "repository_url" { value = aws_ecr_repository.consumer_repo.repository_url }


############################################
# ECR Repository: Worker
############################################
variable "worker_repo_name" {
  description = "ECR repo name for the Worker service"
  type        = string
  default     = "worker"
}

resource "aws_ecr_repository" "worker_repo" {
  name                 = var.worker_repo_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }

  # AES256 by default; flip to KMS if you want like the other repo
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = var.worker_repo_name }
}

resource "aws_ecr_lifecycle_policy" "worker_clean" {
  repository = aws_ecr_repository.worker_repo.name
  policy     = <<JSON
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images older than 14 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 30 images (any tag)",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": { "type": "expire" }
    }
  ]
}
JSON
}

output "worker_repository_name" {
  value       = aws_ecr_repository.worker_repo.name
  description = "Worker ECR repository name"
}

output "worker_repository_url" {
  value       = aws_ecr_repository.worker_repo.repository_url
  description = "Worker ECR repository URL"
}

