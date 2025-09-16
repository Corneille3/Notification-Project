/*# Uses your existing var.aws_region/provider
data "aws_caller_identity" "me" {}

# 1) Turn Security Hub on for this account/region
resource "aws_securityhub_account" "this" {}

# 2) Subscribe to common standards
resource "aws_securityhub_standards_subscription" "fbp" {
  # AWS Foundational Security Best Practices v1
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  # CIS AWS Foundations Benchmark v1.4.0
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

# 3) (Optional) Send new HIGH/CRITICAL findings to email via SNS using EventBridge
variable "security_alert_email" {
  description = "Email to receive Security Hub alerts (leave blank to skip)"
  type        = string
  default     = ""
}

resource "aws_sns_topic" "sec_alerts" {
  name = "securityhub-alerts"
}

resource "aws_sns_topic_subscription" "sec_email" {
  count     = var.security_alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.sec_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}

# EventBridge rule: new imported findings with HIGH/CRITICAL severity
resource "aws_cloudwatch_event_rule" "securityhub_high" {
  name        = "securityhub-high-crit"
  description = "Route Security Hub HIGH/CRITICAL findings to SNS"
  event_pattern = jsonencode({
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "Severity": { "Label": ["HIGH","CRITICAL"] },
        "RecordState": ["ACTIVE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_to_sns" {
  rule      = aws_cloudwatch_event_rule.securityhub_high.name
  target_id = "sns"
  arn       = aws_sns_topic.sec_alerts.arn
}

# Allow EventBridge to publish to the SNS topic
resource "aws_sns_topic_policy" "sec_alerts_policy" {
  arn    = aws_sns_topic.sec_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sns:Publish",
      Resource  = aws_sns_topic.sec_alerts.arn
    }]
  })
}
*/