# Puppet Infrastructure on AWS - Terraform Configuration

This Terraform configuration deploys a complete Puppet infrastructure on AWS, including:

- 1 Puppet Master server (t3.large - 8GB RAM, 20GB storage)
- 2 Puppet Agent nodes (t2.medium - 4GB RAM, 20GB storage each)
  - Frontend agent
  - Backend agent
- Complete VPC networking setup
- Security groups with appropriate access rules
- Ubuntu 22.04 LTS on all instances

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Public Subnet (10.0.1.0/24)                   │ │
│  │                                                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │ │
│  │  │ Puppet Master│  │ App Frontend │  │ App Backend│ │ │
│  │  │  (t3.large)  │  │  (t2.medium) │  │ (t2.medium)│ │ │
│  │  │   8GB RAM    │  │   4GB RAM    │  │  4GB RAM   │ │ │
│  │  │   20GB disk  │  │   20GB disk  │  │  20GB disk │ │ │
│  │  │   Port 8140  │  │   Port 3000  │  │  Port 8080 │ │ │
│  │  └──────────────┘  └──────────────┘  └────────────┘ │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                              │                              │
└──────────────────────────────┼──────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Internet Gateway   │
                    └─────────────────────┘
```

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **AWS CLI**: Configured with credentials (`aws configure`)
3. **Terraform**: Version 1.0 or higher installed
4. **EC2 Key Pair**: Create a key pair in your AWS region for SSH access

## Files Structure

```
terraform/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This file
└── user_data/
    ├── puppet_master.sh       # Puppet Master installation script
    └── puppet_agent.sh        # Puppet Agent installation script
```

## Quick Start

### 1. Create EC2 Key Pair

If you don't have a key pair, create one:

```bash
aws ec2 create-key-pair \
  --key-name puppet-key \
  --query 'KeyMaterial' \
  --output text > puppet-key.pem

chmod 400 puppet-key.pem
```

### 2. Configure Variables

Copy the example variables file and update it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your key pair name:

```hcl
key_pair_name = "puppet-key"  # Use your key pair name
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `key_pair_name` | EC2 key pair name | - | **Yes** |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `subnet_cidr` | Public subnet CIDR | `10.0.1.0/24` | No |
| `master_instance_type` | Puppet Master instance type | `t3.large` (8GB RAM) | No |
| `agent_instance_type` | Puppet Agent instance type | `t2.medium` (4GB RAM) | No |
| `common_tags` | Common resource tags | See variables.tf | No |

## Outputs

After successful deployment, you'll see:

- **Public IPs**: For all three instances
- **Private IPs**: Internal VPC addresses
- **SSH Commands**: Ready-to-use SSH connection commands
- **Application URLs**: Direct links to frontend and backend apps

Example output:

```
puppet_master_public_ip = "54.123.45.67"
app_frontend_public_ip = "54.123.45.68"
app_backend_public_ip = "54.123.45.69"

ssh_connection_commands = {
  puppet_master = "ssh -i /path/to/puppet-key.pem ec2-user@54.123.45.67"
  app_frontend  = "ssh -i /path/to/puppet-key.pem ec2-user@54.123.45.68"
  app_backend   = "ssh -i /path/to/puppet-key.pem ec2-user@54.123.45.69"
}
```

## Security Groups

The configuration creates a security group with the following rules:

| Port | Protocol | Source | Description |
|------|----------|--------|-------------|
| 22 | TCP | 0.0.0.0/0 | SSH access |
| 8140 | TCP | VPC CIDR | Puppet Server |
| 3000 | TCP | 0.0.0.0/0 | Frontend app |
| 8080 | TCP | 0.0.0.0/0 | Backend app |

## Connecting to Instances

### SSH Access

```bash
# Connect to Puppet Master
ssh -i /path/to/your-key.pem ubuntu@<puppet_master_ip>

# Connect to Frontend Agent
ssh -i /path/to/your-key.pem ubuntu@<frontend_ip>

# Connect to Backend Agent
ssh -i /path/to/your-key.pem ubuntu@<backend_ip>
```

### Verify Puppet Installation

On Puppet Master:
```bash
sudo systemctl status puppetserver
sudo /opt/puppetlabs/bin/puppetserver --version
```

On Puppet Agents:
```bash
sudo systemctl status puppet
sudo /opt/puppetlabs/bin/puppet agent --test
```

### Check Certificate Signing

On Puppet Master, list certificate requests:
```bash
sudo /opt/puppetlabs/bin/puppetserver ca list --all
```

The agents should automatically connect due to `autosign = true` in the configuration.

## Managing the Infrastructure

### View Current State

```bash
terraform show
```

### Update Infrastructure

1. Modify the `.tf` files or `terraform.tfvars`
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

### Destroy Infrastructure

⚠️ **Warning**: This will delete all resources!

```bash
terraform destroy
```

## Puppet Configuration

### Puppet Master

- **Installation**: Puppet Server 7
- **Memory**: Configured for 512MB (suitable for t3.small)
- **Autosign**: Enabled for automatic agent certificate signing
- **DNS Names**: Configured with private IP and hostname

### Puppet Agents

- **Installation**: Puppet Agent 7
- **Run Interval**: 30 minutes
- **Server**: Automatically configured to connect to puppet-master
- **Reports**: Enabled

## Application Setup

### Frontend (app-frontend)
- Node.js 18.x pre-installed
- Accessible on port 3000
- Next.js application ready to deploy

### Backend (app-backend)
- Java 17 (Amazon Corretto) pre-installed
- Accessible on port 8080
- Spring Boot application ready to deploy

## Troubleshooting

### Check User Data Logs

```bash
ssh -i your-key.pem ubuntu@<instance-ip>
sudo cat /var/log/user-data.log
```

### Puppet Server Not Starting

```bash
# Check Java memory settings
sudo cat /etc/default/puppetserver

# Check logs
sudo journalctl -u puppetserver -f
```

### Agent Not Connecting

```bash
# On agent, check connectivity
ping puppet-master
telnet puppet-master 8140

# Check Puppet agent logs
sudo journalctl -u puppet -f

# Manual test run
sudo /opt/puppetlabs/bin/puppet agent --test
```

### Check Security Groups

```bash
# From AWS CLI
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id)
```

## Cost Estimation

Approximate monthly costs (us-east-1 region):

- 1 x t3.large instance (Puppet Master): ~$60/month
- 2 x t2.medium instances (Agents): ~$67/month
- 60 GB EBS storage (gp3): ~$5/month
- Data transfer: Variable based on usage
- **Total**: ~$130-140/month

Use Reserved Instances or Savings Plans for production to reduce costs by up to 72%.

## Best Practices

1. **Key Management**: Never commit `.pem` files or `terraform.tfvars` with sensitive data
2. **State Files**: Use S3 backend for team collaboration
3. **Security**: Restrict SSH access to specific IP ranges in production
4. **Monitoring**: Enable CloudWatch monitoring for production workloads
5. **Backups**: Regular snapshots of EBS volumes
6. **Updates**: Keep Puppet and system packages updated

## Advanced Configuration

### Using Remote State

Create `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "puppet-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Multiple Environments

Use Terraform workspaces:

```bash
terraform workspace new staging
terraform workspace new production
terraform workspace select staging
```

## Support and Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Puppet Documentation](https://puppet.com/docs/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## License

This configuration is provided as-is for educational and development purposes.
