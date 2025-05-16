# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_k8s_profile" {
  name = "my_ec2_k8s_profile"
  role = aws_iam_role.ec2_k8s_mgmt_role.name
}

resource "aws_instance" "my_k8s_mgmt_instance" {
  ami                         = "ami-07a6f770277670015"
  instance_type               = "t3.small"
  key_name                    = "final_keypair"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  iam_instance_profile  = aws_iam_instance_profile.ec2_k8s_profile.name
  tags = {
    Name = "k8s-management-ec2-instance-otel"
  }
  # Security group to allow SSH access
  security_groups = [aws_security_group.k8s_mgmt_sg.id]
  user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum install -y git unzip jq
        
        # Install AWS CLI
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install

        # Install Docker
        sudo amazon-linux-extras enable docker
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker

        # Install kubectl
        curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl
        chmod +x ./kubectl
        mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
        echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

        # Install eksctl
        ARCH=amd64
        PLATFORM=$(uname -s)_$ARCH
        curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
        tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
        sudo mv /tmp/eksctl /usr/local/bin

        # Install Helm
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh

        EOF 

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}

resource "time_sleep" "wait-instance-setup" {
  create_duration = "200s"
  depends_on      = [aws_instance.my_k8s_mgmt_instance]
}

# Deploy K8s Cluster
resource "null_resource" "create_k8s_cluster" {
  triggers = {
    always_run = "${timestamp()}"
  }
  connection {
    type        = "ssh"
    host        = aws_instance.my_k8s_mgmt_instance.public_ip
    user        = "ec2-user"
    private_key = var.ssh_private_key #file("${var.ssh_keypair_path}")
  }

  #Uploading the necessary files to the EC2 management instance
  provisioner "file" {
    source      = "./eks_cluster"   # Local file
    destination = "/home/ec2-user" # Remote path
  }

  provisioner "file" {
    source      = "./helm"   # Local file
    destination = "/home/ec2-user" # Remote path
  }

  provisioner "file" {
    source      = "./k8s"   # Local file
    destination = "/home/ec2-user" # Remote path
  }
  
  provisioner "file" {
    source      = "./opentelemetry-helm-charts"   # Local file
    destination = "/home/ec2-user" # Remote path
  }

  provisioner "file" {
    source      = "./tests"   # Local file
    destination = "/home/ec2-user" # Remote path
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/eks_cluster/setup_cluster.sh",
      "/home/ec2-user/eks_cluster/setup_cluster.sh",
      "chmod +x /home/ec2-user/eks_cluster/setup_addons.sh",
      "/home/ec2-user/eks_cluster/setup_addons.sh",
      "chmod +x /home/ec2-user/helm/deploy_helm.sh",
      "chmod +x /home/ec2-user/helm/upgrade_app.sh",
      "chmod +x /home/ec2-user/k8s/deploy_k8s_manifest.sh",
      "chmod +x /home/ec2-user/tests/test_deployment.sh",
    ]
  }

  depends_on = [
    time_sleep.wait-instance-setup,
    aws_instance.my_k8s_mgmt_instance
  ]
}


output "cluster_info"{
  description = "Cluster Information"
  value       = "NOTE: Deletion of cluster not managed by Terraform. Please use `eksctl` to delete the cluster before destroying the terraform resources"
}

output "k8s_management_instance_public_ip" {
  description = "The public IP address of the K8s management EC2 instance"
  value       = aws_instance.my_k8s_mgmt_instance.public_ip
}
