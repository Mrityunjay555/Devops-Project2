# Terraform configuration for Puppet Master and Agents on AWS
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Use Ubuntu 22.04 LTS AMI ID
locals {
  ami_id = "ami-0c398cb65a93047f2"  # Ubuntu 22.04 LTS in us-east-1
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "puppet_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "puppet_igw" {
  vpc_id = aws_vpc.puppet_vpc.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Public Subnet
resource "aws_subnet" "puppet_public_subnet" {
  vpc_id                  = aws_vpc.puppet_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "puppet_public_rt" {
  vpc_id = aws_vpc.puppet_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.puppet_igw.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

# Route Table Association
resource "aws_route_table_association" "puppet_public_rta" {
  subnet_id      = aws_subnet.puppet_public_subnet.id
  route_table_id = aws_route_table.puppet_public_rt.id
}

# Security Group
resource "aws_security_group" "puppet_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Puppet infrastructure"
  vpc_id      = aws_vpc.puppet_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access"
  }

  # Puppet Server port
  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Puppet Server port"
  }

  # Backend application port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend application port"
  }

  # Frontend application port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend application port"
  }



  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# User data scripts are defined inline for each instance

# Puppet Master EC2 Instance
resource "aws_instance" "puppet_master" {
  ami                    = local.ami_id
  instance_type          = var.master_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.puppet_sg.id]
  subnet_id              = aws_subnet.puppet_public_subnet.id
  user_data              = base64encode(templatefile("${path.module}/scripts/puppet-master-setup.sh", {
    master_hostname = "puppet-master"
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name    = "puppet-master"
    Project = var.project_name
    Role    = "puppet-master"
  }
}

# Frontend Puppet Agent EC2 Instance
resource "aws_instance" "app_frontend" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.puppet_sg.id]
  subnet_id              = aws_subnet.puppet_public_subnet.id
  user_data              = base64encode(templatefile("${path.module}/scripts/puppet-agent-setup.sh", {
    master_private_ip = aws_instance.puppet_master.private_ip
    master_hostname   = "puppet-master"
    agent_hostname    = "app-frontend"
  }))

  depends_on = [aws_instance.puppet_master]

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
  }

  tags = {
    Name    = "app-frontend"
    Project = var.project_name
    Role    = "puppet-agent"
    App     = "frontend"
  }
}

# Backend Puppet Agent EC2 Instance
resource "aws_instance" "app_backend" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.puppet_sg.id]
  subnet_id              = aws_subnet.puppet_public_subnet.id
  user_data              = base64encode(templatefile("${path.module}/scripts/puppet-agent-setup.sh", {
    master_private_ip = aws_instance.puppet_master.private_ip
    master_hostname   = "puppet-master"
    agent_hostname    = "app-backend"
  }))

  depends_on = [aws_instance.puppet_master]

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
  }

  tags = {
    Name    = "app-backend"
    Project = var.project_name
    Role    = "puppet-agent"
    App     = "backend"
  }
}

