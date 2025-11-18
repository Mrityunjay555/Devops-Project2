# Variables for Puppet Infrastructure
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "master_instance_type" {
  description = "EC2 instance type for Puppet Master (needs more resources)"
  type        = string
  default     = "t3.medium"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "puppet-infrastructure"
}