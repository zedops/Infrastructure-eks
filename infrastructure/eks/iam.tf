# Create the IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "eks-cluster-role"
  }
}


# Attach the necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#######
# Resource: Create EBS CSI IAM Policy 
resource "aws_iam_policy" "ebs_csi_iam_policy" {
  name        = "sohtek-AmazonEKS_EBS_CSI_Driver_Policy"
  path        = "/"
  description = "EBS CSI IAM Policy"
  #policy = data.http.ebs_csi_iam_policy.body
  policy = data.http.ebs_csi_iam_policy.response_body
}

output "ebs_csi_iam_policy_arn" {
  value = aws_iam_policy.ebs_csi_iam_policy.arn
}

data "template_file" "assume_role_policy_ebs_csi" {
  template = file("${path.module}/assume-role-policy.json")
  vars = {
    cluster_oidc_provider_url = substr(module.eks.cluster_oidc_issuer_url, 8, -1)
    iam_oidc_provider_arn     = module.eks.oidc_provider_arn
    namespace                 = "kube-system"
    serviceAccount_name       = "ebs-csi-controller-sa"
  }
}

resource "aws_iam_role" "ebs_csi_iam_role" {
  assume_role_policy = data.template_file.assume_role_policy_ebs_csi.rendered
  name               = "sohtek-ebs-csi-iam-role"
}

# Associate EBS CSI IAM Policy to EBS CSI IAM Role
resource "aws_iam_role_policy_attachment" "ebs_csi_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.ebs_csi_iam_policy.arn
  role       = aws_iam_role.ebs_csi_iam_role.name
}

output "ebs_csi_iam_role_arn" {
  description = "EBS CSI IAM Role ARN"
  value       = aws_iam_role.ebs_csi_iam_role.arn
}

#######
data "aws_eks_cluster" "cluster" {
  name       = "sohtek"
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = "sohtek"
  depends_on = [module.eks]
}

data "tls_certificate" "cert" {
  url        = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  depends_on = [module.eks]
}
