variable "cleanup_schedule" {
  type = string
  description = "Cron expression for cleanup. Default is to run every 3 days"
  default = "0 0 */3 * *"
}

variable "public_subnet_cidr" {
  default = {
    "us-east-1a" = "10.0.3.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
  type = map(string)
}