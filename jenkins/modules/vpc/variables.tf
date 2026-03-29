variable "environment_name" {
  type = string
}

variable "vpc_cidr_range" {
  default = "10.0.0.0/16"
  type = string
}

variable "private_subnet_cidr" {
  default = "10.0.0.0/24"
  type = string
}

variable "public_subnet_cidr" {
  type = map(string)
}

variable "az" {
  type = string
}