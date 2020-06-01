###
# AWS CLOUD
# |_AWS REGION (eg us-east-1)
#   |_AZ1 (eg us-east-1a)
# |_DATA CENTER 1...
#   |_AZ2 (eg us-east-1b)
# |_DATA CENTER 1...
# |_VPC (can span multiple AZs)
#   |_ELB
#   |_INTERNET GATEWAY (to make subnet public)
#   |_(NAT GATEWAY INSTANCE or SERVICE (ec2 traffic forwarder, self-managed or aws-managed. for private subnet to access internet)
#   |_ROUTE TABLE
#   |_SUBNET (must reside in 1 AZ)
#     |_EC2

# Use Transit Gateway which uses VPC attachment (n-to-1-to-n hub-and-spoke model) to route traffic between VPCs internally (and not over the internet).

# Typical AWS to On-prem Connection:
# [AWS] <-VPG-CustomerGateway-> [On-prem]
# or
# [AWS] <-VPG-DirectConnect-CustomerGateway-> [On-prem]
# * Direct Connect is not redundant. Use VPN.
###

# vpc starter #
1. $ aws ec2 create-vpc --cidr-block #.#.#.#/16
2. $ aws ec2 create-subnet --vpc-id vpc-123 --cidr-block #.#.#.#/24 ### 1
    $ aws ec2 create-subnet --vpc-id vpc-123 --cidr-block #.#.#.#/24 ### 2

3. $ aws ec2 create-internet-gateway
    $ aws ec2 attach-internet-gateway --vpc-id vpc-123 --internet-gateway-id igw-123
4. $ aws ec2 create-route-table --vpc-id vpc-123
    $ aws ec2 create-route --route-table-id rtb-123 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-123

5. ($ aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-123" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}' ### get subnet id to associate rtb with subnet)
   $ aws ec2 associate-route-table --subnet-id subnet-123 --route-table-id rtb-123

   ($ aws ec2 modify-subnet-attribute --subnet-id subnet-123 --map-public-ip-on-launch ### modify public ip addressing of subnet so ec2 launched in subnet auto receives public ip. else associate eip with ec2 after launch)

6. $ aws ec2 create-security-group --group-name grp-ssh --description "" --vpc-id vpc-123
   $ aws ec2 authorize-security-group-ingress --group-id sg-123 --protocol tcp --port 22 --cidr #.#.#.#/24

7. $ aws ec2 create-key-pair --key-name key-123 --query 'KeyMaterial' --output text > key-123.pem
   ($ chmod 400 key-123.pem)
   $ aws ec2 run-instances --image-id ami-123 --count 1 --instance-type t2.micro --key-name key-123 --security-group-ids sg-123 --subnet-id subnet-123

   $ aws ec2 describe-instances --instance-id i-123 ### is i-123 running?
   $ ssh -i "key-123.pem" ec2-user@#.#.#.# ### when i-123 is running