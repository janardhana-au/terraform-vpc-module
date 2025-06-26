output "vpc_id" {
    value = aws_vpc.main.id
  
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet_ids[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet_ids[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database_subnet_ids[*].id
}