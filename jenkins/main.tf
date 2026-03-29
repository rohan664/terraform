module "vpc" {
    source = "./modules/vpc"
    environment_name = "DEV"
    vpc_cidr_range = "10.0.0.0/16"
    private_subnet_cidr = "10.0.0.0/24"
    public_subnet_cidr = var.public_subnet_cidr
    az = "us-east-1a"
}

module "iam" {
  source = "./modules/iam"
  environment_name = "DEV"
}

module "elb" {
  source = "./modules/elb"
  name   = "${local.identifier}-ELB-SG"
  vpc_id = module.vpc.vpc_id
  elb_name = "Jenkins-master-node"
  public_subnet_id = module.vpc.public_subnet_id
  instance_id = module.ec2.instance_id
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  environment_name = "DEV"
  private_subnet_id = module.vpc.private_subnet_id
  ami = "ami-0ec10929233384c7f"
  instance_type = local.instance_type
  instance_profile_name = module.iam.instance_profile_name
  instance_size = local.instance_size
  bootstrap_script = local.bootstrap_script
  instance_user = local.instance_user
  bastion_info = local.bastion_info
  elb_security_group = module.elb.security_group
}

