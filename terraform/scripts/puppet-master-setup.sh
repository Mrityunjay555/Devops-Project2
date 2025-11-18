#!/bin/bash
set -e

# Puppet Master Setup Script for Ubuntu 22.04
# This script sets up a Puppet Master server

# Variables
MASTER_HOSTNAME="${master_hostname}"
LOG_FILE="/var/log/puppet-master-setup.log"

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
    MASTER_PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    MASTER_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    MASTER_AWS_HOSTNAME=$(ip_to_hostname "$MASTER_PRIVATE_IP")
    
    log "Master Private IP: $MASTER_PRIVATE_IP"
    log "Master Public IP: $MASTER_PUBLIC_IP"
    log "Master AWS Hostname: $MASTER_AWS_HOSTNAME"
}

# Install Java 17 (required for Puppet Server)
install_java() {
    log "Installing OpenJDK 17..."
    apt update
    apt install -y openjdk-17-jdk
    
    # Verify Java installation
    java -version 2>&1 | head -1 | tee -a "$LOG_FILE"
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
    systemctl stop puppetserver || true
    systemctl stop puppet || true
    apt-get remove --purge -y puppetserver puppet-agent puppet-common || true
    rm -rf /etc/puppetlabs /opt/puppetlabs /var/lib/puppet /var/log/puppet /var/run/puppetserver
    apt-get autoremove -y
}

# Setup hosts file
setup_hosts() {
    log "Updating /etc/hosts with Puppet Master information..."
    
    # Remove any existing puppet entries
    sed -i '/puppetmaster/d' /etc/hosts
    sed -i '/puppet /d' /etc/hosts
    sed -i "/$MASTER_AWS_HOSTNAME/d" /etc/hosts
    
    # Add puppet master entries
    echo "$MASTER_PRIVATE_IP $MASTER_AWS_HOSTNAME puppet puppetmaster" >> /etc/hosts
    
    log "Updated /etc/hosts:"
    grep -E "(puppet|$MASTER_AWS_HOSTNAME)" /etc/hosts | tee -a "$LOG_FILE"
}

# Install and configure Puppet Server
install_puppet_server() {
    log "Installing Puppet Server..."
    apt install -y puppetserver
    
    # Configure Puppet Server memory settings
    log "Configuring Puppet Server memory settings..."
    sed -i 's/^JAVA_ARGS=.*/JAVA_ARGS="-Xms1g -Xmx1g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"/' /etc/default/puppetserver || true
    
    # Create puppet manifest directory
    mkdir -p /etc/puppetlabs/code/environments/production/manifests
    
    # Create a simple site.pp manifest with correct syntax
    cat > /etc/puppetlabs/code/environments/production/manifests/site.pp << 'EOF'
# Default class for common configuration
class base {
  # Ensure basic packages are installed
  package { ["git", "curl", "wget"]:
    ensure => installed,
  }
  
  # Create a test file to verify Puppet is working
  file { "/tmp/puppet-managed":
    ensure  => file,
    content => "This file was created by Puppet\n",
    mode    => "0644",
  }
}

# Default node configuration
node default {
  include base
}

# Frontend node configuration
node "app-frontend" {
  include base
  
  file { "/tmp/frontend-node":
    ensure  => file,
    content => "Frontend node managed by Puppet\n",
    mode    => "0644",
  }
}

# Backend node configuration  
node "app-backend" {
  include base
  
  file { "/tmp/backend-node":
    ensure  => file,
    content => "Backend node managed by Puppet\n", 
    mode    => "0644",
  }
}
EOF

    # Set proper ownership
    chown -R puppet:puppet /etc/puppetlabs/code
    
    log "Starting and enabling Puppet Server..."
    systemctl enable puppetserver
    systemctl start puppetserver
    
    # Wait for Puppet Server to start
    log "Waiting for Puppet Server to start..."
    sleep 30
    
    # Check if Puppet Server is running
    if systemctl is-active --quiet puppetserver; then
        log "Puppet Server is running successfully"
    else
        log "ERROR: Puppet Server failed to start"
        systemctl status puppetserver | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Verify Puppet Server installation
verify_installation() {
    log "Verifying Puppet Server installation..."
    
    # Check if port 8140 is listening
    if netstat -tlnp | grep :8140; then
        log "Puppet Server is listening on port 8140"
    else
        log "WARNING: Puppet Server is not listening on port 8140"
    fi
    
    # Test CA functionality
    log "Testing Puppet CA functionality..."
    /opt/puppetlabs/bin/puppetserver ca list --all | tee -a "$LOG_FILE"
}

# Main execution
main() {
    log "Starting Puppet Master setup..."
    
    get_instance_info
    install_java
    install_puppet_repo
    clean_puppet
    setup_hosts
    install_puppet_server
    verify_installation
    
    log "Puppet Master setup completed successfully!"
    log "Puppet Server should be running on port 8140"
    log "To sign agent certificates, run: sudo /opt/puppetlabs/bin/puppetserver ca sign --all"
    log "To list pending certificates, run: sudo /opt/puppetlabs/bin/puppetserver ca list"
    
    # Display summary
    echo "========================================="
    echo "Puppet Master Setup Complete!"
    echo "========================================="
    echo "Master Private IP: $MASTER_PRIVATE_IP"
    echo "Master Public IP: $MASTER_PUBLIC_IP"
    echo "Puppet Server Port: 8140"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Wait for agents to connect"
    echo "2. Sign agent certificates: sudo /opt/puppetlabs/bin/puppetserver ca sign --all"
    echo "3. Test agent connection: sudo /opt/puppetlabs/bin/puppet agent --test"
    echo "========================================="
}

# Execute main function
main 2>&1 | tee -a "$LOG_FILE"