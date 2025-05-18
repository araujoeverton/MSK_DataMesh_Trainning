output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.vpc_main.id
}

output "subnet_ids" {
  description = "IDs das subnets criadas"
  value       = aws_subnet.subnets[*].id
}

output "igw_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "security_group_id" {
  description = "ID do Security Group principal"
  value       = aws_security_group.sg_default.id
}