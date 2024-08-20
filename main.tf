# configure the AWS Provider
provider "aws" {
  region = "us-west-2"
  access_key = "xxx"
  secret_key = "xxx"
}

# create a VPC
resource "aws_vpc" "portfolio" {
  cidr_block = "10.2.0.0/20"
  tags = {
    Name = "portfolio"
  }
}

# master Host EC2 Instance

resource "aws_instance" "master" {
  ami           = "ami-0cf2b4e024cdb6960"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private01.id
  security_groups = [aws_security_group.bastion.name] ? cluster-kubernetes
  key_name      = "prod"
  tags = {
    Name = "bastion"
  }
}

# node Host EC2 Instance

resource "aws_instance" "node" {
  ami           = "ami-0cf2b4e024cdb6960"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private02.id
  security_groups = [aws_security_group.bastion.name] ? cluster-kubernetes
  key_name      = "prod"
  tags = {
    Name = "bastion"
  }
}

# bastion Host EC2 Instance

resource "aws_instance" "bastion" {
  ami           = "ami-0cf2b4e024cdb6960"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.bastion.name] ? bastion
  key_name      = "prod"
  tags = {
    Name = "bastion"
  }
}


# Subnets

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.portfolio.id
  cidr_block = "10.2.0.0/24"

  tags = {
    Name = "public"
    Access = "public"
  }
}
resource "aws_subnet" "private01" {
  vpc_id     = aws_vpc.portfolio.id
  cidr_block = "10.2.1.0/24"

  tags = {
    Name = "private01"
    Access = "private"
  }
}
resource "aws_subnet" "private02" {
  vpc_id     = aws_vpc.portfolio.id
  cidr_block = "10.2.2.0/24"

  tags = {
    Name = "private02"
    Access = "private"
  }
}

# internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.portfolio.id

  tags = {
    Name = "portfolio"
  }
}

# public Route Table
# nuevo

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.portfolio.id

  route {
    cidr_block = "10.2.0.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

## route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  }
##
  tags = {
    Name = "public"
  }
}
# private Route Table

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.portfolio.id
  tags = {
    Name = "private"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "nat-gateway"
  }
}

# route for Private Subnets
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# subnet Route Table Associations

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private01" {
  subnet_id      = aws_subnet.private01.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private02" {
  subnet_id      = aws_subnet.private02.id
  route_table_id = aws_route_table.private.id
}

# security Group for Bastion Host

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.portfolio.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion"
  }
}

