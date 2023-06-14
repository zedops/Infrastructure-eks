module "vpc" {
  source         = "./vpc"
  vpc001_enabled = var.vpc001_enabled
}

module "eks" {
  source = "./eks"
}
