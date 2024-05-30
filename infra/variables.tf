variable "lambda_scraper_name" {
  default = "impulsiona-milhas-scraper"
}

variable "lambda_scheduler_name" {
  default = "impulsiona-milhas-subscriber-notificator"
}

variable "gateway_name" {
  default = "ImpulsionaMilhas"
}

variable "tags" {
  default = {
    Project = "ImpulsionaMilhas"
  }
}

variable "telegram_bot_url" {
  default = "https://impulsionamilhaapp.vand.dev"
}

variable "custom_domain" {
  type = string
  default = "impulsionamilhasapi.vand.dev"
}