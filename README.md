# AWS starter pack

This is about as classic as it gets for the AWS beginners. A simple setup with VPC, Subnets, Routing tables, EC2 instances, Load balancer and Autoscaling. More details in the README in source folder. Feel free to use this as starting point.


## Terraform

The infrastructure code is in Terraform. However hand coding everything quickly leads to a big code base. Leverage not Re-Invent. So this code repo uses the already created [Terraform modules](https://registry.terraform.io/namespaces/terraform-aws-modules) for different AWS functionality. VPC, EC2, Loadbalancer and Autoscaling are implemented via Terraform modules.

## GitHub Actions

If you want to use GitHub Actions to compile and deploy code then that is possible. Make sure you follow the README in the source folder to set up the GitHub with AWS Secrets. 
