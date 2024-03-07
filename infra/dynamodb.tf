resource "aws_dynamodb_table" "offers-table" {
  name           = "ImpulsionaMilhasOffers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "Title"

  attribute {
    name = "Title"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationDate"
    enabled        = true
  }

  tags = var.tags
}