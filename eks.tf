module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name = "aurora-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    "kubernetes.io/cluster/aurora-cluster" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "aurora-cluster"
  cluster_version = "1.28"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = false

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "aurora-node-group-1"

      instance_types = ["t3.large"] # I can't afford this at the moment lol.

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}

data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  arn = module.eks.oidc_provider_arn
}


# S3 Access
resource "aws_iam_policy" "k8s_s3_access_policy" {
  name   = "k8s_s3_access_policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.aurora_data.arn}/*",
        "${aws_s3_bucket.aurora_data.arn}"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "k8s_s3_access_role" {
  name = "k8s_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${data.aws_iam_openid_connect_provider.eks_oidc_provider.url}:sub" = "system:serviceaccount:default:aurora-s3-access"
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "k8s_s3_access_policy_attachment" {
  role       = aws_iam_role.k8s_s3_access_role.name
  policy_arn = aws_iam_policy.k8s_s3_access_policy.arn
}
