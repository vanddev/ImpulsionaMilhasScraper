terraform {
  backend "s3" {
    bucket = "terraform-state-vanddev"
    key    = "impulsionamilhas/state"
    region = "sa-east-1"
  }
}