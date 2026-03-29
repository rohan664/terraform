locals {
  instance_profile_name = join("_",["jenkins",var.environment_name])
  iam_role_name = join("_",["jenkins",var.environment_name])
  policy_arn = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore","arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}