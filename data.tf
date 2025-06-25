data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "peering_vpc" {
  filter {
    name   = "tag:Name"
    values = ["custom_vpc"]  # Replace with your VPC name
  }
}

/* data "aws_route_table" "main"{
    vpc_id = data.aws_vpc.peering_vpc.id
    filter {
        name= "association.main"
        values = ["true"]
      
    }
} */

data "aws_subnet" "peer_subnet"{
    vpc_id = data.aws_vpc.peering_vpc.id

    cidr_block = "172.31.80.0/20"
    
    }
