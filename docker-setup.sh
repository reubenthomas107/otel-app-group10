#!/bin/bash
echo ">>> BEGINNING EC2 BOOTSTRAP" > ~/otel-boot.log
# Redirect all output to log for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Install updates and packages
yum update -y
amazon-linux-extras install docker -y
yum install -y docker git curl

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Set up OpenTelemetry demo as ec2-user
su - ec2-user -c "
  cd /home/ec2-user
  git clone https://github.com/open-telemetry/opentelemetry-demo.git
  cd opentelemetry-demo
  docker-compose up -d
"
