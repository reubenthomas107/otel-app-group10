resource "aws_security_group" "docker_sg" {
  name        = "otel-docker-sg"
  description = "Allow Docker ports"

  ingress {
    from_port   = 22
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "otel_docker_ec2" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.large"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.docker_sg.id]

  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              yum install -y docker git curl
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              cd /home/ec2-user
              git clone https://github.com/open-telemetry/opentelemetry-demo.git
              cd opentelemetry-demo
              docker-compose up -d
              newgrp docker
              EOF

  tags = {
    Name = "OpenTelemetryDockerNode"
  }
}
