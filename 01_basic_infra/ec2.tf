# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "demo_ec2_instance-${each.key}"
  instance_type = "t3.micro"
  ami           = data.aws_ami.amazon_linux.id

  # Convert the list of subnets to a map for for_each
  for_each = { for idx, subnet_id in module.vpc.private_subnets : idx => subnet_id }

  subnet_id = each.value

  create_security_group = true
  security_group_name = "demo_ec2_sg"
  security_group_use_name_prefix = true
  security_group_description = "Security group for demo EC2 instances"
  security_group_vpc_id      = module.vpc.vpc_id

  security_group_ingress_rules = {
    http_from_alb = {
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      description                  = "HTTP from ALB"
      referenced_security_group_id = module.alb.security_group_id
    }
    ssh_from_vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      description = "SSH from VPC"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
  
  # ✅ Egress Rules - Allow all outbound. NAT gateway will provide internet access.
  security_group_egress_rules = {
    all_outbound = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "All outbound traffic"
    }
  }

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # --------------------
  # user_data to install Apache and show instance name
  # --------------------
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              echo "OK from $INSTANCE_ID" > /var/www/html/index.html
              EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}