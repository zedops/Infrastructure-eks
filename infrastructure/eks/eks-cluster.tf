# Create the EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "sohtek"
  cluster_version = "1.27"

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = aws_iam_role.ebs_csi_iam_role.arn
      resolve_conflicts        = "OVERWRITE"
    }
  }

  vpc_id                   = aws_vpc.eks_vpc.id
  subnet_ids               = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  control_plane_subnet_ids = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  eks_managed_node_group_defaults = {
    instance_types = ["t2.large", "t2.small"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.large"]
      capacity_type  = "SPOT"
    }
  }
}

