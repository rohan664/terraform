resource "aws_vpc" "jenkins" {
  cidr_block = var.vpc_cidr_range
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "jenkins-${var.environment_name}"
  }
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins.id
  tags = {
    Name = "jenkins-${var.environment_name}-igw"
  }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.jenkins.id
    cidr_block = var.private_subnet_cidr
    map_public_ip_on_launch = false
    availability_zone = var.az
    
    tags = {
      Name = "jenkins-private-subnet-${var.environment_name}"
    }
}

resource "aws_subnet" "public_subnet" {
    for_each = var.public_subnet_cidr
    vpc_id = aws_vpc.jenkins.id
    cidr_block = each.value
    map_public_ip_on_launch = true
    availability_zone = each.key
    
    tags = {
      Name = "jenkins-public-subnet-${var.environment_name}-${each.key}"
    }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.jenkins.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
  tags = {
    Name = "jenkins-public-route-${var.environment_name}"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_subnet
  route_table_id = aws_route_table.public_route.id
  subnet_id = each.value.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_nat_gateway" {
  connectivity_type = "public"
  availability_mode = "regional"
  vpc_id = aws_vpc.jenkins.id

  tags = {
    Name = "jenkins-nat-${var.environment_name}"
  }

  depends_on = [ aws_internet_gateway.jenkins_igw ]
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.jenkins.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_nat_gateway.id
  }
  tags = {
    Name = "jenkins-private-route-${var.environment_name}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}