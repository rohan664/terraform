variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "elb_name" {
  type = string
}

variable "public_subnet_id" {
  type = list(string)
}

variable "instance_id" {
  type = string
}