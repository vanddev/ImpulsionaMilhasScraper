variable "function_name" {
  type = string
  description = "Name of the lambda function"
}

variable "role_arn" {
  type = string
  description = "Arn of the lambda's role"
}

variable "layers" {
  type = list(string)
  default = []
  description = "Arns of the lambda layers to attach to lambda"
}

variable "lambda_handler" {
  type = string
  description = "Handler method to lambda"
}

variable "source_path" {
  type = string
  description = "Path or path for the source code"
}

variable "source_file" {
  type = string
  description = "File or path for the source code"
}

variable "create_layer_requirements" {
  type = bool
  description = "Flag to trigger the publish step of lambda layer with the libraries on requirements file"
  default = true
}

variable "environment" {
  type = any
  description = "Env vars for the lambda function"
  default = {}
}

variable "tags" {
  type = any
}