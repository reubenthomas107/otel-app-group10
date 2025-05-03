resource "aws_instance" "my_docker_instance" {
  ami                         = "ami-07a6f770277670015"
  instance_type               = "t2.medium" #"t2.large"
  key_name                    = "final_keypair"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
#   iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "ec2-otel-docker-instance"
  }
  # Security group to allow SSH access
  security_groups = [aws_security_group.docker_mgmt_sg.id]
  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git
        sudo yum install aws-cli


        # Install Docker
        sudo amazon-linux-extras enable docker
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Install Docker Compose
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        sudo curl -SL https://github.com/docker/compose/releases/download/v2.35.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

        # Download Project Repository
        git clone https://github.com/open-telemetry/opentelemetry-demo.git
        cd opentelemetry-demo/

        sudo docker compose up --force-recreate --remove-orphans --detach

        EOF 

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }
  # TODO: Consider using EFS Storage

  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}

output "docker_instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.my_docker_instance.public_ip
}

output "docker_web_store_url" {
  description = "The public URL of the web store - docker"
  value       = "http://${aws_instance.my_docker_instance.public_ip}:8080"
}
