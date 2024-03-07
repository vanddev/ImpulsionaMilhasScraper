data "aws_iam_policy_document" "lambda_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.lambda_scraper_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_scraper_name}-policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = data.aws_iam_policy_document.lambda_policy.json
}

module "scraper_lambda" {
  source = "./modules/lambda"
  function_name = var.lambda_scraper_name
  lambda_handler = "handler.lambda_handler"
  role_arn    = aws_iam_role.iam_for_lambda.arn
  source_file = "handler.py"
  source_path = abspath("../src/scraper")
  tags        = var.tags
}

resource "aws_lambda_permission" "lambda_permission" {
  depends_on = [aws_api_gateway_rest_api.gtw, module.scraper_lambda]
  statement_id  = "AllowGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.scraper_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.gtw.execution_arn}/*"
}

module "scheduler_lambda" {
  source = "./modules/lambda"
  function_name = var.lambda_scheduler_name
  lambda_handler = "handler.lambda_handler"
  role_arn = aws_iam_role.iam_for_lambda.arn
  create_layer_requirements = false
  source_file = "handler.py"
  source_path = abspath("../src/scheduler")
  environment = {"NEWEST_OFFERS_TABLE" = aws_dynamodb_table.offers-table.id}
  tags        = var.tags
}