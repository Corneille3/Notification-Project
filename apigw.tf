resource "aws_apigatewayv2_vpc_link" "internal" {
  name               = "internal-vpc-link"
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  security_group_ids = [aws_security_group.vpc_link_sg.id]
}

resource "aws_apigatewayv2_api" "internal" {
  name          = "internal-http-api"
  protocol_type = "HTTP"
}

# Use ALB listener ARN as integration_uri; overwrite Host to match ALB rules
resource "aws_apigatewayv2_integration" "Requestor" {
  api_id                 = aws_apigatewayv2_api.internal.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.internal.id
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
  request_parameters     = { "overwrite:header.host" = "requestor.internal.local" }
}
resource "aws_apigatewayv2_integration" "Worker" {
  api_id                 = aws_apigatewayv2_api.internal.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.internal.id
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
  request_parameters     = { "overwrite:header.host" = "worker.internal.local" }
}
resource "aws_apigatewayv2_integration" "Administrator" {
  api_id                 = aws_apigatewayv2_api.internal.id
  integration_type       = "HTTP_PROXY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.internal.id
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.http.arn
  payload_format_version = "1.0"
  request_parameters     = { "overwrite:header.host" = "administrator.internal.local" }
}

# Routes
resource "aws_apigatewayv2_route" "Requestor_root" {
  api_id    = aws_apigatewayv2_api.internal.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.Requestor.id}"
}
resource "aws_apigatewayv2_route" "Requestor_proxy" {
  api_id    = aws_apigatewayv2_api.internal.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.Requestor.id}"
}
resource "aws_apigatewayv2_route" "Worker_proxy" {
  api_id    = aws_apigatewayv2_api.internal.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.Worker.id}"
}
resource "aws_apigatewayv2_route" "Administrator_proxy" {
  api_id    = aws_apigatewayv2_api.internal.id
  route_key = "ANY /notify/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.Administrator.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.internal.id
  name        = "$default"
  auto_deploy = true
}
