Create a basic infra setup with EC2 instances behind a loadbalancer. 
Use the already provided AWS Terraform modules rather than handcoding everything. Leverage not re-invent.

NOTES:
1. Private subnet created for running App servers.
2. Database subnet (supported in module) for running databases if needed. They are also private subnet. 
3. Public subnet to run Webservers. Not getting used here. But created.
4. Loadbalancer created in public subnet to direct traffic to EC2 servers running in private subnet.
5. NAT gateways are created so that EC2 servers in private subnet can access internet to download OS patches.
6. NAT is expensive. Destory the infra once you are done.
