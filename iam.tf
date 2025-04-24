# Create an IAM role for EC2 instances running
resource "aws_iam_role" "ec2_k8s_mgmt_role" {
  name = "k8s-ec2-mgmt-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect    = "Allow"
      Sid       = ""
    }]
  })
}


resource "aws_iam_role_policy" "ec2_k8s_mgmt_role_policy" {
  name   = "k8s-ec2-eks-full-access-policy"
  role   = aws_iam_role.ec2_k8s_mgmt_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        },
        {
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:ssm:*:${var.account_id}:parameter/aws/*",
                "arn:aws:ssm:*::parameter/aws/*"
            ],
            "Effect": "Allow"
        },
        {
             "Action": [
               "kms:CreateGrant",
               "kms:DescribeKey"
             ],
             "Resource": "*",
             "Effect": "Allow"
        },
        {
             "Action": [
               "logs:PutRetentionPolicy"
             ],
             "Resource": "*",
             "Effect": "Allow"
        }        
    ]
})
}


# Attaching all required cluster policies for managing the cluster and resources
resource "aws_iam_role_policy_attachment" "eks_mgmt_policies" {
  for_each = toset([
    "AmazonEC2FullAccess",
    "AWSCloudFormationFullAccess",
    "IAMFullAccess",
    "AmazonEC2ContainerRegistryFullAccess",
    "AmazonVPCFullAccess",
    "AmazonSSMManagedInstanceCore"
])

  role       = aws_iam_role.ec2_k8s_mgmt_role.name
  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
}
