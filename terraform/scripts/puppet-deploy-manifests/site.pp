# Puppet site manifest for Todo App deployment
# This configures the deployment of frontend and backend containers

node /frontend/ {
  include docker_base
  include todo_frontend_deploy
}

node /backend/ {
  include docker_base  
  include todo_backend_deploy
}

class docker_base {
  # Ensure Docker is installed and running
  package { 'docker.io':
    ensure => present,
  }
  
  service { 'docker':
    ensure  => running,
    enable  => true,
    require => Package['docker.io'],
  }
  
  # Install docker-compose
  exec { 'install-docker-compose':
    command => '/usr/bin/curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose',
    creates => '/usr/local/bin/docker-compose',
    require => Package['curl'],
  }
  
  # Create app directory
  file { '/opt/todo-app':
    ensure => directory,
    owner  => 'ubuntu',
    group  => 'ubuntu',
    mode   => '0755',
  }
}

class todo_frontend_deploy {
  # Create frontend directory
  file { '/opt/todo-app/frontend':
    ensure  => directory,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0755',
    require => File['/opt/todo-app'],
  }
  
  # Frontend docker-compose.yml
  file { '/opt/todo-app/frontend/docker-compose.yml':
    ensure  => present,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0644',
    content => "version: '3.8'
services:
  todo-frontend:
    image: \${DOCKERHUB_USERNAME}/todo-frontend:latest
    container_name: todo-frontend
    ports:
      - \"3000:3000\"
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_API_URL=http://\${BACKEND_IP}:8080/api
    restart: unless-stopped
    networks:
      - todo-network

networks:
  todo-network:
    driver: bridge
",
    require => File['/opt/todo-app/frontend'],
  }
  
  # Auto-deployment script
  file { '/opt/todo-app/frontend/auto-deploy.sh':
    ensure  => present,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0755',
    content => "#!/bin/bash
# Auto-deployment script for frontend
cd /opt/todo-app/frontend
docker-compose pull
docker-compose up -d --force-recreate
docker image prune -f
",
    require => File['/opt/todo-app/frontend'],
  }
  
  # Cron job for auto-deployment (every 5 minutes)
  cron { 'frontend-auto-deploy':
    command => '/opt/todo-app/frontend/auto-deploy.sh >> /var/log/frontend-deploy.log 2>&1',
    user    => 'ubuntu',
    minute  => '*/5',
    require => File['/opt/todo-app/frontend/auto-deploy.sh'],
  }
}

class todo_backend_deploy {
  # Create backend directory
  file { '/opt/todo-app/backend':
    ensure  => directory,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0755',
    require => File['/opt/todo-app'],
  }
  
  # Backend docker-compose.yml
  file { '/opt/todo-app/backend/docker-compose.yml':
    ensure  => present,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0644',
    content => "version: '3.8'
services:
  mongodb:
    image: mongo:7
    container_name: todo-mongodb
    ports:
      - \"27017:27017\"
    environment:
      - MONGO_INITDB_DATABASE=todoapp
    volumes:
      - mongodb_data:/data/db
    networks:
      - todo-network
    restart: unless-stopped

  todo-backend:
    image: \${DOCKERHUB_USERNAME}/todo-backend:latest
    container_name: todo-backend
    ports:
      - \"8080:8080\"
    environment:
      - SPRING_DATA_MONGODB_URI=mongodb://mongodb:27017/todoapp
      - SPRING_PROFILES_ACTIVE=production
    depends_on:
      - mongodb
    networks:
      - todo-network
    restart: unless-stopped

volumes:
  mongodb_data:

networks:
  todo-network:
    driver: bridge
",
    require => File['/opt/todo-app/backend'],
  }
  
  # Auto-deployment script
  file { '/opt/todo-app/backend/auto-deploy.sh':
    ensure  => present,
    owner   => 'ubuntu',
    group   => 'ubuntu',
    mode    => '0755',
    content => "#!/bin/bash
# Auto-deployment script for backend
cd /opt/todo-app/backend
docker-compose pull
docker-compose up -d --force-recreate
docker image prune -f
",
    require => File['/opt/todo-app/backend'],
  }
  
  # Cron job for auto-deployment (every 5 minutes)
  cron { 'backend-auto-deploy':
    command => '/opt/todo-app/backend/auto-deploy.sh >> /var/log/backend-deploy.log 2>&1',
    user    => 'ubuntu',
    minute  => '*/5',
    require => File['/opt/todo-app/backend/auto-deploy.sh'],
  }
}