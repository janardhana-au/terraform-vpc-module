locals {
  common_tags = {
    project = var.project
    environment = var.environment
    Terraform = "true"
  }
  availability_zone = slice(data.aws_availability_zones.available.names, 0, 2)
}