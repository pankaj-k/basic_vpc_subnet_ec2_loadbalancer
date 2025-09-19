# # Fetch the latest Amazon Linux 2 AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# module "ec2" {
#   source = "terraform-aws-modules/ec2-instance/aws"

#   # Ensure EC2 instances are created only after VPC, subnets, and NAT gateway are ready.
#   # Otherwise they will fail to access internet to download updates and install Apache.
#   depends_on = [
#     module.vpc.natgw_ids,                 # Wait for NAT Gateway to be created so that EC2 in private subnet can use it.
#     module.vpc.private_route_table_ids,   # Wait for route tables
#     module.vpc.vpc_id                     # Wait for VPC
#   ]

#   name = "demo_ec2_instance-${each.key}"
#   instance_type = "t3.micro"
#   ami           = data.aws_ami.amazon_linux.id

#   # Convert the list of subnets to a map for for_each
#   for_each = { for idx, subnet_id in module.vpc.private_subnets : idx => subnet_id }

#   subnet_id = each.value

#   create_security_group = true
#   security_group_name = "demo_ec2_sg"
#   security_group_use_name_prefix = true
#   security_group_description = "Security group for demo EC2 instances"
#   security_group_vpc_id      = module.vpc.vpc_id

#   security_group_ingress_rules = {
#     http_from_alb = {
#       from_port                    = 80
#       to_port                      = 80
#       ip_protocol                  = "tcp"
#       description                  = "HTTP from ALB"
#       referenced_security_group_id = module.alb.security_group_id
#     }
#     ssh_from_vpc = {
#       from_port   = 22
#       to_port     = 22
#       ip_protocol = "tcp"
#       description = "SSH from VPC"
#       cidr_ipv4   = module.vpc.vpc_cidr_block
#     }
#   }
  
#   # ✅ Egress Rules - Allow all outbound. NAT gateway will provide internet access.
#   security_group_egress_rules = {
#     all_outbound = {
#       ip_protocol = "-1"
#       cidr_ipv4   = "0.0.0.0/0"
#       description = "All outbound traffic"
#     }
#   }

#   create_iam_instance_profile = true
#   iam_role_description        = "IAM role for EC2 instance"
#   iam_role_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   # --------------------
#   # user_data to install Apache and show instance name
#   # --------------------
#   user_data = <<-EOF
#   #!/bin/bash
#   exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
#   yum update -y
#   yum install -y httpd
#   systemctl enable httpd
#   systemctl start httpd

#   # Wait for Apache to start
#   sleep 5

#   # Get instance hostname
#   HOSTNAME=$(hostname)

#   # Create index.html with proper permissions
#   echo "OK from $HOSTNAME" > /var/www/html/index.html
#   chown apache:apache /var/www/html/index.html
#   chmod 644 /var/www/html/index.html
#   chown -R apache:apache /var/www/html/
#   chmod -R 755 /var/www/html/
#   systemctl restart httpd
#   sleep 3
#   systemctl status httpd
#   curl -I http://localhost/ || echo "Local curl failed"
#   ls -la /var/www/html/
#   cat /var/www/html/index.html
#   echo "User data script completed at $(date)"
#   EOF

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }