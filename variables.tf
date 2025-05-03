variable "ssh_keypair" {
  description = "EC2 Key Pair name"
  default     = "final_keypair.pem"
}

variable "ssh_private_key" {
  type = string
  description = "Private Key for SSH access to K8s Management Instance"
  sensitive = true
  default = ""
}

variable "ssh_keypair_path" {
  description = "Path to the EC2 Key Pair"
  default     = "../../final_keypair.pem"
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "619715105204"
}