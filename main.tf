#vpc-dv
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = merge(
    var.vpc_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    })
} 
# roboshop-dev
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.igw_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    })
} 
#roboshop-dev-us-east-1a
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.availability_zone[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    var.public_subnet_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-public-${local.availability_zone[count.index]}"
    })
}


#roboshop-dev-us-east-1a
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zone[count.index]
  
  tags = merge(
    var.private_subnet_tags,

    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-private-${local.availability_zone[count.index]}"
    })
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.availability_zone[count.index]
  
  tags = merge(
    var.database_tags,

    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-database-${local.availability_zone[count.index]}"
    })
}

resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = merge(
    var.eip_tags,

    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.nat_tags,

    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    })

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-public"
    })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-private"
    })
}


resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-database"
    })
}


resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}


resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_req? 1:0
  peer_vpc_id   = data.aws_vpc.peering_vpc.id
  vpc_id        = aws_vpc.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  auto_accept = true
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-peering"
    })

}

resource "aws_route_table" "peering_rt" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-peering_rt"
    })
}

resource "aws_route" "peer_routes" {
  count = var.is_peering_req? 1:0
  route_table_id            = aws_route_table.peering_rt.id
  destination_cidr_block    = data.aws_vpc.peering_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[count.index].id
}

resource "aws_route_table" "peering_rt_peer_side" {
  vpc_id = data.aws_vpc.peering_vpc.id
  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-peering_rt"
    })
}

resource "aws_route" "peer_routes_peer_side" {
  count = var.is_peering_req? 1:0
  route_table_id            = aws_route_table.peering_rt_peer_side.id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[count.index].id
}

resource "aws_route_table_association" "peering" {

  route_table_id = aws_route_table.peering_rt_peer_side.id
  subnet_id = data.aws_subnet.peer_subnet.id
}



