# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# The security group for ASG instances is created by the module.
resource "aws_security_group" "ec2_sg" {
  name        = "demo-ec2-sg"
  description = "Security group for EC2 in ASG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id] # only ALB allowed
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-ec2-sg"
  }
}


module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  # Ensure EC2 instances are created only after VPC, subnets, and NAT gateway are ready.
  # Otherwise they will fail to access internet to download updates and install Apache.
  depends_on = [
    module.vpc.natgw_ids,               # Wait for NAT Gateway to be created so that EC2 in private subnet can use it.
    module.vpc.private_route_table_ids, # Wait for route tables
    module.vpc.vpc_id                   # Wait for VPC
  ]

  name                = "demo-asg"
  vpc_zone_identifier = module.vpc.private_subnets # Private subnet for EC2 instances.
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  # Use ELB health checks to determine instance health. EC2 type only checks if EC2 is up.
  # But we check HTTP on port 80 and expect 200 OK. If Apache fails, EC2 health check would still pass, but ELB health check would fail
  # ASG should replace instances when your web application fails, not just when EC2 fails
  health_check_type = "ELB"
  force_delete      = true

  # Target Tracking Scaling based on average CPU usage of the ASG (all instances in ASG)
  scaling_policies = {
    avg-cpu-target-50 = {
      policy_type = "TargetTrackingScaling"
      # How long a new EC2 instance needs before its metrics (like CPU) are considered “valid” for scaling decisions.
      estimated_instance_warmup = 300 # shorter warmup for quick demo, tweak as needed
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
  }

  # IAM role for SSM
  create_iam_instance_profile = true
  iam_role_name               = "demo-asg-role"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  security_groups = [aws_security_group.ec2_sg.id] # Use the SG created above.

  # EC2 config
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
HOSTNAME=$(hostname)
echo "OK from $HOSTNAME" > /var/www/html/index.html
EOF
  )
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# Notifications for scaling up or down of servers in ASG
# CREATE SNS TOPIC FOR ASG NOTIFICATIONS
resource "aws_sns_topic" "asg_notifications" {
  name = "demo-asg-notifications"

  tags = {
    Name        = "ASG Notifications"
    Environment = "dev"
  }
}

# SNS TOPIC POLICY (allows ASG to publish)
resource "aws_sns_topic_policy" "asg_notifications" {
  arn = aws_sns_topic.asg_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.asg_notifications.arn
      }
    ]
  })
}

# EMAIL SUBSCRIPTION (replace with your email)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.asg_notifications.arn
  protocol  = "email"
  endpoint  = "changethisemail@example.com" # Replace with your email
}

# ASG NOTIFICATION CONFIGURATION
resource "aws_autoscaling_notification" "demo_notifications" {
  group_names = [module.asg.autoscaling_group_name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn

  depends_on = [module.asg]
}
