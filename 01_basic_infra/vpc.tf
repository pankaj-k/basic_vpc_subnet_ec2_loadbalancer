module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "demo_vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  # If the ec2 instances in private subnet need internet access. Like OS updates.
  # Outside world cannot initiate connection to instances in private subnet.
  enable_nat_gateway = true
  #   enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
