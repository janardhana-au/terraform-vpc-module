variable "cidr_block" {
    type = string
    # default = "10.0.0.0/16"
    description = "its cidr range for vpc"
}


variable "project" {
    type = string
  
}

variable "environment" {
    type = string
  
}

variable "public_subnet_cidrs" {

  type = list(string)
}

variable "public_subnet_tags" {

  type = map(string)
  default = {}
}

variable "private_subnet_cidrs" {

  type = list(string)
}

variable "private_subnet_tags" {

  type = map(string)
  default = {}
}

variable "vpc_tags" {
    type = map(string)
    default = {}
}
  
variable "igw_tags" {
    type = map(string)
    default = {}
  
}

variable "database_tags" {
    type = map(string)
    default = {}
  
}

variable "database_subnet_cidrs" {

  type = list(string)
}

variable "eip_tags" {
    type = map(string)
    default = {}
  
}
variable "nat_tags" {
    type = map(string)
    default = {}
  
}

variable "is_peering_req" {
    default = false
  
}