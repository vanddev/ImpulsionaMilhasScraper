locals {
  layer_path         = "layer_files"
  layer_name         = "requirements_${var.function_name}"
  layer_zip_name     = "${local.layer_name}.zip"
  requirements_name  = "requirements.txt"
  requirements_path  = "${var.source_path}/${local.requirements_name}"
  lambda_file_source = "${var.function_name}_payload.zip"
}

# create zip file from requirements.txt. Triggers only when the file is updated
resource "null_resource" "lambda_layer" {
  count = var.create_layer_requirements ? 1 : 0
  triggers = {
    requirements = filesha1(local.requirements_path)
  }
  # the command to install python and dependencies to the machine and zips
  provisioner "local-exec" {
    command = "sed -i 's/\r//' ${path.module}/create_layer_zip.sh && ${path.module}/create_layer_zip.sh ${local.layer_path} ${local.requirements_path} ${local.layer_zip_name}"
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  count      = var.create_layer_requirements ? 1 : 0
  depends_on = [null_resource.lambda_layer]
  filename   = local.layer_zip_name
  layer_name = local.layer_name

  compatible_runtimes = ["python3.8"]
}

resource "null_resource" "delete_zip_after_publish" {
  depends_on = [aws_lambda_layer_version.lambda_layer]

  provisioner "local-exec" {
    command = "rm -rf ${local.layer_path} && rm -rf ${local.layer_zip_name}"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${var.source_path}/${var.source_file}"
  output_path = local.lambda_file_source
}

resource "aws_lambda_function" "lambda" {
  filename         = local.lambda_file_source
  function_name    = var.function_name
  handler          = var.lambda_handler
  role             = var.role_arn
  layers           = setunion(var.create_layer_requirements ? [aws_lambda_layer_version.lambda_layer[0].arn]:[], var.layers)
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.8"
  environment      = var.environment
  tags             = var.tags
}

resource "null_resource" "delete_lambda_zip_after_publish" {
  depends_on = [aws_lambda_function.lambda]

  provisioner "local-exec" {
    command = "rm -rf ${local.lambda_file_source}"
  }
}