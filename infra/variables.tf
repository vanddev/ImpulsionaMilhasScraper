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
    Name = "ImpulsionaMilhas"
  }
}

variable "telegram_bot_url" {
  default = "https://impulsionamilhas2-m6r3gl47.b4a.run"
}