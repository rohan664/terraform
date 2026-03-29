terraform {
  required_version = "1.14.8"
  required_providers {
    aws = {
        version = "6.38.0"
        source = "hashicorp/aws"
    }
    null = {
      source  = "hashicorp/null"
      version = "= 3.2.3"
    }
  }
  backend "s3" {
    bucket = "terraform-state-jenkins-bucket"
    key = "jenkins/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = false
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
        "ManagedBy" = "Terraform"
        "resource" = "Jenkins-server"
    }
  }
}