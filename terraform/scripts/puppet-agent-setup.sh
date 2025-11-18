#!/bin/bash
set -e

# Puppet Agent Setup Script for Ubuntu 22.04
# This script sets up a Puppet Agent

# Variables from Terraform
MASTER_PRIVATE_IP="${master_private_ip}"
MASTER_HOSTNAME="${master_hostname}"
AGENT_HOSTNAME="${agent_hostname}"
LOG_FILE="/var/log/puppet-agent-setup.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Convert an IP (10.0.1.195) to AWS-style hostname (ip-10-0-1-195.ec2.internal)
ip_to_hostname() {
    echo "ip-$(echo "$1" | tr '.' '-').ec2.internal"
}

# Get instance metadata
get_instance_info() {
    log "Getting instance metadata..."
    AGENT_PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    AGENT_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    AGENT_AWS_HOSTNAME=$(ip_to_hostname "$AGENT_PRIVATE_IP")
    MASTER_AWS_HOSTNAME=$(ip_to_hostname "$MASTER_PRIVATE_IP")
    
    log "Agent Private IP: $AGENT_PRIVATE_IP"
    log "Agent Public IP: $AGENT_PUBLIC_IP"
    log "Agent AWS Hostname: $AGENT_AWS_HOSTNAME"
    log "Master Private IP: $MASTER_PRIVATE_IP"
    log "Master AWS Hostname: $MASTER_AWS_HOSTNAME"
}

# Install Puppet repository
install_puppet_repo() {
    log "Installing Puppet repository package..."
    cd /tmp
    wget https://apt.puppetlabs.com/puppet8-release-jammy.deb
    dpkg -i puppet8-release-jammy.deb
    rm puppet8-release-jammy.deb
    apt update
}

# Clean any existing Puppet installation
clean_puppet() {
    log "Cleaning any existing Puppet installation..."
    systemctl stop puppet || true
    apt-get remove --purge -y puppet-agent puppet-common || true
    rm -rf /etc/puppetlabs /opt/puppetlabs /var/lib/puppet /var/log/puppet /var/run/puppet
    apt-get autoremove -y
}

# Setup hosts file
setup_hosts() {
    log "Updating /etc/hosts with Puppet Master and Agent information..."
    
    # Remove any existing puppet entries
    sed -i '/puppetmaster/d' /etc/hosts
    sed -i '/puppetclient/d' /etc/hosts
    sed -i '/puppet /d' /etc/hosts
    sed -i "/$MASTER_AWS_HOSTNAME/d" /etc/hosts
    sed -i "/$AGENT_AWS_HOSTNAME/d" /etc/hosts
    
    # Add puppet master and agent entries
    echo "$MASTER_PRIVATE_IP $MASTER_AWS_HOSTNAME puppet puppetmaster" >> /etc/hosts
    echo "$AGENT_PRIVATE_IP $AGENT_AWS_HOSTNAME $AGENT_HOSTNAME" >> /etc/hosts
    
    log "Updated /etc/hosts:"
    grep -E "(puppet|$MASTER_AWS_HOSTNAME|$AGENT_AWS_HOSTNAME)" /etc/hosts | tee -a "$LOG_FILE"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Install Docker dependencies
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    apt update
    
    # Install Docker
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu
    
    log "Docker installation completed"
}

# Install and configure Puppet Agent
install_puppet_agent() {
    log "Installing Puppet Agent..."
    apt install -y puppet-agent
    
    # Create puppet configuration directory
    mkdir -p /etc/puppetlabs/puppet
    
    # Create puppet.conf configuration
    log "Creating Puppet Agent configuration..."
    cat > /etc/puppetlabs/puppet/puppet.conf << EOF
[main]
certname = $AGENT_HOSTNAME
server = puppet
environment = production
runinterval = 30m

[agent]
report = true
pluginsync = true
EOF

    # Clean SSL directory to avoid issues
    rm -rf /etc/puppetlabs/puppet/ssl
    
    # Set proper ownership
    chown -R puppet:puppet /etc/puppetlabs/puppet || true
    
    log "Starting and enabling Puppet Agent..."
    systemctl enable puppet
    systemctl start puppet
    
    # Check if Puppet Agent is running
    if systemctl is-active --quiet puppet; then
        log "Puppet Agent is running successfully"
    else
        log "WARNING: Puppet Agent may not be running properly"
        systemctl status puppet | tee -a "$LOG_FILE"
    fi
}

# Wait for Puppet Master to be ready
wait_for_master() {
    log "Waiting for Puppet Master to be ready..."
    
    # Wait up to 5 minutes for the master to be ready
    for i in {1..30}; do
        if nc -z "$MASTER_PRIVATE_IP" 8140 2>/dev/null; then
            log "Puppet Master is ready on port 8140"
            return 0
        fi
        log "Waiting for Puppet Master... (attempt $i/30)"
        sleep 10
    done
    
    log "WARNING: Puppet Master is not responding on port 8140"
    return 1
}

# Test initial connection to Puppet Master
test_connection() {
    log "Testing initial connection to Puppet Master..."
    
    # Run puppet agent test (this will create a certificate request)
    log "Running initial puppet agent test..."
    /opt/puppetlabs/bin/puppet agent --test --waitforcert=0 || true
    
    log "Certificate request should now be pending on the Puppet Master"
    log "Run the following on the Puppet Master to sign certificates:"
    log "sudo /opt/puppetlabs/bin/puppetserver ca sign --all"
}



# Verify installation
verify_installation() {
    log "Verifying Puppet Agent installation..."
    
    # Check puppet agent version
    /opt/puppetlabs/bin/puppet --version | tee -a "$LOG_FILE"
    
    # Check if puppet agent service is enabled
    if systemctl is-enabled puppet >/dev/null 2>&1; then
        log "Puppet Agent service is enabled"
    else
        log "WARNING: Puppet Agent service is not enabled"
    fi
    
    # Check Docker service
    if systemctl is-active --quiet docker; then
        log "Docker service is running"
        docker --version | tee -a "$LOG_FILE"
    else
        log "WARNING: Docker service is not running"
    fi
    

}

# Main execution
main() {
    log "Starting Puppet Agent setup for $AGENT_HOSTNAME..."
    
    get_instance_info
    install_puppet_repo
    clean_puppet
    setup_hosts
    install_docker
    install_puppet_agent
    wait_for_master
    test_connection

    verify_installation
    
    log "Puppet Agent setup completed!"
    
    # Display summary
    echo "========================================="
    echo "Puppet Agent Setup Complete!"
    echo "========================================="
    echo "Agent Hostname: $AGENT_HOSTNAME"
    echo "Agent Private IP: $AGENT_PRIVATE_IP"
    echo "Agent Public IP: $AGENT_PUBLIC_IP"
    echo "Master Private IP: $MASTER_PRIVATE_IP"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Sign the certificate on Puppet Master:"
    echo "   sudo /opt/puppetlabs/bin/puppetserver ca sign --certname $AGENT_HOSTNAME"
    echo "2. Test the agent:"
    echo "   sudo /opt/puppetlabs/bin/puppet agent --test"
    echo "========================================="
}

# Execute main function
main 2>&1 | tee -a "$LOG_FILE"