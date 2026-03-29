output "vpc_id" {
  value = aws_vpc.jenkins.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "public_subnet_id" {
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}