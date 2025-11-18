# Output values for Puppet infrastructure
output "puppet_master_public_ip" {
  description = "Public IP address of the Puppet Master"
  value       = aws_instance.puppet_master.public_ip
}

output "puppet_master_private_ip" {
  description = "Private IP address of the Puppet Master"
  value       = aws_instance.puppet_master.private_ip
}

output "app_frontend_public_ip" {
  description = "Public IP address of the Frontend App server"
  value       = aws_instance.app_frontend.public_ip
}

output "app_frontend_private_ip" {
  description = "Private IP address of the Frontend App server"
  value       = aws_instance.app_frontend.private_ip
}

output "app_backend_public_ip" {
  description = "Public IP address of the Backend App server"
  value       = aws_instance.app_backend.public_ip
}

output "app_backend_private_ip" {
  description = "Private IP address of the Backend App server"
  value       = aws_instance.app_backend.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.puppet_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.puppet_public_subnet.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.puppet_sg.id
}



output "ssh_connection_commands" {
  description = "SSH commands to connect to instances"
  value = {
    puppet_master = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.puppet_master.public_ip}"
    app_frontend  = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.app_frontend.public_ip}"
    app_backend   = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.app_backend.public_ip}"

  }
}

output "puppet_urls" {
  description = "Puppet-related URLs and commands"
  value = {
    puppet_master_console = "https://${aws_instance.puppet_master.public_ip}:8140"
    sign_certificates     = "sudo /opt/puppetlabs/bin/puppetserver ca sign --all"
    list_certificates     = "sudo /opt/puppetlabs/bin/puppetserver ca list"
  }
}

output "application_urls" {
  description = "Application URLs"
  value = {
    frontend_app = "http://${aws_instance.app_frontend.public_ip}:3000"
    backend_app  = "http://${aws_instance.app_backend.public_ip}:8080"
  }
}

