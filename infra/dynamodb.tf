resource "aws_dynamodb_table" "offers-table" {
  name           = "ImpulsionaMilhasOffers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "OriginalURL"

  attribute {
    name = "OriginalURL"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationDate"
    enabled        = true
  }

  tags = var.tags
}