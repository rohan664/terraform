resource "aws_iam_instance_profile" "instance_profile" {
    name = local.instance_profile_name
    role = local.iam_role_name

    tags = {
        Name = local.instance_profile_name
    }
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_iam_role" {
  name = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json

  tags = {
    Name = local.iam_role_name
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
    for_each = toset(local.policy_arn)
    policy_arn = each.value
    role = aws_iam_role.instance_iam_role.name
}