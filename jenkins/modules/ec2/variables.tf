variable "vpc_id" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "instance_size" {
  type = number
}

variable "bootstrap_script" {
  type = string
}

variable "instance_user" {
  type = string
}

variable "bastion_info" {
  type = map(string)
}

variable "elb_security_group" {
  type = string
}