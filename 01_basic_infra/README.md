Create a basic infra setup with EC2 instances behind a loadbalancer. 
Use the already provided AWS Terraform modules rather than handcoding everything. Leverage not re-invent.

NOTES:
1. Private subnet created for running App servers.
2. Database subnet (supported in module) for running databases if needed. They are also private subnet. 
3. Public subnet to run Webservers. Not getting used here. But created.
4. Loadbalancer created in public subnet to direct traffic to EC2 servers running in private subnet.
5. NAT gateways are created so that EC2 servers in private subnet can access internet to download OS patches.
6. NAT is expensive. Destory the infra once you are done.
7. NAT takes time to come up. Delay the EC2 server creation till NAT is up. Otherwise Apache install will fail on EC2.
8. Using AWS EC2 Terraform module to enable session manager based access to EC2 instance via AWS Console UI. 

######################################################################################################################
Github actions has been configured to run it when you check in the code on main.
Each repo in Github has to be configured with your AWS secrets to enable it access. 

Step: Store AWS credentials in GitHub Secrets

Go to your repo → Settings → Secrets and variables → Actions and add:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION (e.g., us-east-1)

The delete of infra is manual. Best practice is to keep it that way Prod.