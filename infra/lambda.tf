locals {
  layer_path        = "layer_files"
  layer_zip_name    = "layer.zip"
  layer_name        = "requirements_${var.lambda_name}"
  requirements_name = "requirements.txt"
  requirements_path = "../${local.requirements_name}"
}

# create zip file from requirements.txt. Triggers only when the file is updated
resource "null_resource" "lambda_layer" {
  triggers = {
    requirements = filesha1(local.requirements_path)
  }
  # the command to install python and dependencies to the machine and zips
  provisioner "local-exec" {
    command = "sed -i 's/\r//' create_layer_zip.sh && ./create_layer_zip.sh ${local.layer_path} ${local.requirements_path} ${local.layer_zip_name}"
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  depends_on = [null_resource.lambda_layer]
  filename   = local.layer_zip_name
  layer_name = local.layer_name

  compatible_runtimes = ["python3.8"]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../src/handler.py"
  output_path = "lambda_function_payload.zip"
}

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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
}

resource "aws_lambda_function" "scraper_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_name
  handler       = "handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.8"
}

resource "aws_lambda_permission" "lambda_permission" {
  depends_on = [aws_api_gateway_rest_api.gtw, aws_lambda_function.scraper_lambda]
  statement_id  = "AllowGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scraper_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.gtw.execution_arn}/*"
}