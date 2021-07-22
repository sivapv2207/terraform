provider "aws" {
  region  =  "ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraformVpc"
  }
} 
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "publicsubnet"
  }
}
resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "privatesubnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internetgateway"
  }
}
resource "aws_route_table" "pubroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "pubroutetable"
  }
}
resource "aws_route_table_association" "pubassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubroute.id
}
resource "aws_eip" "eip" {
  vpc      = true
}
resource "aws_nat_gateway" "natg" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "nat"
  }
}
resource "aws_route_table" "priroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natg.id
  }
  tags = {
    Name = "priroutetable"
  }
}
resource "aws_route_table_association" "priassociation" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.priroute.id
}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "allow_all"
  }
}
resource "aws_instance" "publicmachine" {
  ami                         =  "ami-0ad704c126371a549"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.pubsub.id
  key_name                    =  "KEY0002"
  vpc_security_group_ids      =  ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address =  true
}
resource "aws_instance" "private" {
  ami                         =  "ami-0ad704c126371a549"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.prisub.id
  key_name                    =  "KEY0002"
  vpc_security_group_ids      =  ["${aws_security_group.allow_all.id}"]
  
}
