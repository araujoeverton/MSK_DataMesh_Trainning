terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configurando Provider
provider "aws" {
  region = var.region
}

# Criando a VPC
resource "aws_vpc" "vpc_main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC_Main"
  }
}

# Criando subnets usando count
resource "aws_subnet" "subnets" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "VPC_Subnet_${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "VPC_IGW"
  }
}

# Route Table
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_Route_Table"
  }
}

# Associação da Route Table com as subnets
resource "aws_route_table_association" "rta_subnet" {
  count          = length(var.subnet_cidrs)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.rt_public.id
}

# Security Group
resource "aws_security_group" "sg_default" {
  name        = "sg_default"
  description = "Security Group padrão para a VPC"
  vpc_id      = aws_vpc.vpc_main.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Porto ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite todo tráfego de saída"
  }

  tags = {
    Name = "SG_Default"
  }
}

# Criando NACLs (opcional, mas recomendado para segurança adicional)
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.vpc_main.id
  
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "VPC_NACL"
  }
}

# Associação do NACL com as subnets
resource "aws_network_acl_association" "nacl_association" {
  count          = length(var.subnet_cidrs)
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.subnets[count.index].id
}