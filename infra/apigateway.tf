locals {

}

resource "aws_api_gateway_rest_api" "gtw" {
  name = var.gateway_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}


resource "aws_api_gateway_resource" "promos" {
  parent_id   = aws_api_gateway_rest_api.gtw.root_resource_id
  path_part   = "promos"
  rest_api_id = aws_api_gateway_rest_api.gtw.id
}

resource "aws_api_gateway_resource" "latest" {
  parent_id   = aws_api_gateway_resource.promos.id
  path_part   = "latest"
  rest_api_id = aws_api_gateway_rest_api.gtw.id
}

resource "aws_api_gateway_method" "latest_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.latest.id
  rest_api_id   = aws_api_gateway_rest_api.gtw.id
}


resource "aws_api_gateway_integration" "lambda_get" {
  depends_on = [module.scraper_lambda]
  http_method = aws_api_gateway_method.latest_get.http_method
  resource_id = aws_api_gateway_resource.latest.id
  rest_api_id = aws_api_gateway_rest_api.gtw.id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri = module.scraper_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.gtw.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.gtw.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.gtw.id
  stage_name    = "dev"
}

resource "aws_api_gateway_base_path_mapping" "mapping_root" {
  api_id      = aws_api_gateway_rest_api.gtw.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  domain_name = var.custom_domain
  base_path = ""
}

resource "aws_api_gateway_base_path_mapping" "mapping_stage" {
  api_id      = aws_api_gateway_rest_api.gtw.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  domain_name = var.custom_domain
  base_path = "*"
}