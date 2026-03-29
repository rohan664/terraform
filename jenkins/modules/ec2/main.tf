resource "aws_security_group" "instance" {
  name   = "jenkins-instance-sg"
  vpc_id = var.vpc_id
  description = "Jenkins ingress and egress access"
  tags = {
    Name = "jenkins-instance-sg"
    Usage = "jenkins-${var.environment_name}"
  }
}

resource "aws_security_group_rule" "web_access" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  description       = "web access"
  source_security_group_id = var.elb_security_group
}

resource "aws_security_group_rule" "bastion_ssh_access" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.instance.id
  type              = "ingress"
  description       = "ssh access"
  source_security_group_id = var.bastion_info.bastion_sgs
}

resource "aws_security_group_rule" "egress_rule_for_jenkins" {
  from_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.instance.id
  to_port = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "provides public access to jenkins"
  type = "egress"
}

resource "aws_network_interface" "instance" {
  subnet_id       = var.private_subnet_id
  security_groups = [aws_security_group.instance.id]
  tags            = {
    Usage = "jenkins-${var.environment_name}"
  }
}

data "aws_key_pair" "ssh_private_key" {
  key_name = "bastion-server"
}

resource "aws_instance" "jenkins" {
  ami                  = var.ami
  instance_type        = var.instance_type
  monitoring           = true
  iam_instance_profile = var.instance_profile_name
  key_name             = data.aws_key_pair.ssh_private_key.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }
  root_block_device {
    volume_size = var.instance_size
    encrypted = true
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.instance.id
  }

  tags = {
    Name = "JENKINS-${upper(var.environment_name)}"
  }
}

data "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id = "jenkins-private"
}

resource "null_resource" "provisioner" {
  triggers = {
    instance_id = aws_instance.jenkins.id
    ami         = aws_instance.jenkins.ami
    user_data   = var.bootstrap_script
  }
  connection {
    host                = aws_instance.jenkins.private_ip
    user                = var.instance_user
    private_key         = data.aws_secretsmanager_secret_version.ssh_private_key.secret_string
    bastion_host        = var.bastion_info.bastion_public_ip
    bastion_user        = var.bastion_info.bastion_user
    bastion_private_key = data.aws_secretsmanager_secret_version.ssh_private_key.secret_string
    timeout             = "180s"
  }

  provisioner "file" {
    content = var.bootstrap_script
    destination = "/var/tmp/bootstrap-cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/bootstrap-cluster.sh",
      "/var/tmp/bootstrap-cluster.sh > /var/tmp/script.out 2>&1",
    ]
  }
}