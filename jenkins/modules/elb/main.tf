resource "aws_security_group" "elb" {
  name   = var.name
  vpc_id = var.vpc_id
  description = "ELB security group"

  tags = {
    Name = var.name
  }
}

resource "aws_security_group_rule" "github_webhook_ingress" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  type              = "ingress"
  description       = "Github webhook IPs"
  cidr_blocks       = ["192.30.252.0/22", "185.199.108.0/22", "140.82.112.0/20"]
}

resource "aws_security_group_rule" "web_access_ingress" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  type              = "ingress"
  description       = "Github webhook IPs"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_rule_for_elb" {
  from_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.elb.id
  to_port = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "provides public access to jenkins"
  type = "egress"
}

resource "aws_lb" "jenkins" {
  name                = var.elb_name
  security_groups     = [aws_security_group.elb.id]
  subnets             = toset(var.public_subnet_id)
  idle_timeout        = 180
  internal            = false
  load_balancer_type  = "application"

#   access_logs {
#     bucket   = var.access_logs_bucket_id
#     enabled  = true
#     interval = 5
#   }

  tags = {
    Name = var.name
  }

#   depends_on = [aws_s3_bucket_policy.access_logs_bucket_policy]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.elb_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/login"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "instance_via_elb" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.instance_id
  port             = 80
}