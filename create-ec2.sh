#!/bin/bash

# Define an array of instance names
instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web")

# Specify domain name and Route 53 hosted zone ID
domain_name="akhildev.online"
hosted_zone_id="Z0895514WYXV2A6F4ZOI"

# Iterate through each instance name in the 'instances' array
for name in ${instances[@]}; do
    if [ $name == "shipping" ] || [ $name == "mysql" ]
    then
       instance_type="t3.medium"
    else
       instance_type="t3.micro"
    fi
 
    # Output information about the instance being created
    echo "Creating instances for: $name with instance type: $instance_type"

    # Output information about the instance being created
    instance_id=$(aws ec2 run-instances --image-id ami-041e2ea9402c46c32 --instance-type $instance_type --security-group-ids sg-02a039261e685ce53 --subnet-id subnet-0cd35fe18dde26230 --query 'Instances[0].InstanceId' --output text)

    # Output confirmation of instance creation
    echo "Instance created for: $name"

    # Tag the instance with a Name tag corresponding to the instance name
    aws ec2 create-tags --resources $instance_id --tags key=Name,value=$name

    # Giving web as public IP address
    if [ $name == "web" ]
    then
    # Wait until the instance is running
       aws ec2 wait instance-running --instance-ids $instance_id
       public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
    # Set the IP address to use for Route 53 record   
       ip_to_use=$public_ip
    else
       private_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
       ip_to_use=$private_ip
    fi

    # Creating Route 53 record
    echo "Creating R53 Record for $name"
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '
    {
        "Comment": "Creating a record set for '$name'"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$name.$domain_name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$ip_to_use'"
            }]
        }
        }]
    }'
done