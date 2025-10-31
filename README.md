# Logstash on Autoscaled EC2 Behind an Application Load Balancer (Terraform)

This project provisions a baseline AWS infrastructure for running Logstash (or any application) on EC2 instances behind an **Application Load Balancer (ALB)**. The setup is built entirely using **Terraform**, leveraging **AWS Terraform modules** rather than manually defining every resource.

> **Principle:** *Leverage, don’t reinvent.*  
> Using proven modules reduces complexity and improves maintainability.

---

## Architecture Overview

The infrastructure creates:

| Component | Purpose |
|----------|---------|
| **VPC** with public and private subnets | Logical networking layout |
| **Private subnets** | Application servers (EC2 instances) run here |
| **Public subnets** | Used by the Application Load Balancer |
| **Application Load Balancer** | Receives HTTPS/HTTP traffic and forwards internally to private EC2 nodes |
| **Autoscaling Group** | Automatically adjusts EC2 capacity based on load |
| **NAT Gateway** | Allows private EC2 instances outbound internet access for updates |
| **S3 Bucket** | Stores ALB access logs (optional) |
| **ACM Certificate + Route 53 DNS (Optional)** | Provides a public HTTPS endpoint |

---

## Key Notes & Behaviors

1. **Private subnets** are used for EC2 application servers.
2. **Public subnets exist**, but only the ALB is placed there.
3. **NAT Gateways** are required so private EC2 instances can install packages/patches.
   - NAT Gateways are billed hourly — **destroy when not needed** to avoid cost.
4. NAT provisioning can take time — you may need to **delay EC2 provisioning** or rely on retries for package install.
5. EC2 access is via **AWS Systems Manager Session Manager**, not SSH.
6. **Autoscaling**
   - Minimum number of EC2 instances is maintained.
   - Can scale on CPU utilization trigger.
   - **Scale-out is fast**; **scale-in can lag ~10 minutes**.
   - To generate CPU load:
     ```bash
     sudo apt install stress-ng -y
     stress-ng --cpu 2 --timeout 300s --metrics-brief
     ```
7. **Email notifications** are sent when scale-in/out events occur (update email in configuration).
8. **ALB access logs** are delivered to S3.

---

## GitHub Actions (CI/CD)

GitHub Actions can automatically run `terraform plan` and `terraform apply` when changes are pushed to `main`.

### Configure GitHub Secrets

Navigate to:  
**Repo → Settings → Secrets and variables → Actions**

Add:

| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key |
| `AWS_REGION` | Example: `us-east-1` |

### Destroying Infrastructure

Destruction is **manual by design** (best practice for production environments).

Run manually 
```terraform destroy```
or use the provided GitHub Actions workflow terraform-destroy.yml.