output "docker_ec2_ip" {
  value = aws_instance.otel_docker_ec2.public_ip
}

output "eks_client_ip" {
  value = aws_instance.eks_client.public_ip
}
