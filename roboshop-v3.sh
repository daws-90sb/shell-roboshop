#!/bi/bash


AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0925237PNVPSE5X635V" # replace with your zone id
DOMAIN_NAME="daws-90sb.online" # replace with your domain id

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ALL_INSTANCES="mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend"

### validation error ###
if [ $# -lt 2 ]; then
     echo -e "$R ERROR :: Alteast 2 arguments required $N"
     echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
     exit 1
fi    


ACTION=$1
shift # first argument will be removed, so $@ does not have action/destroy



if [ "$ACTION" != "create" ]  && [ "$ACTION" != "delete" ]; then
    echo -e " $R ERROR:: First argument must be either create/delete $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

### If all is passed expand to full list ###

if [ "$1" == all ]; then
   if [ "$ACTION" == "create" ]; then
      INSTANCES="$ALL_INSTANCES"
   else 
        # if not create means then normal order will be taken as reverse order and then "tac" command is used as like cat command
        INSTANCES=$(echo "$ALL_INSTANCES" | tr ' ' '\n' | tac | tr '\n' ' ') 
    fi
else 
       INSTANCES="$@"

fi        
      

get_instance_id(){
     name=$1
     aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-$name"  "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text 

}

for instance in $@
do
 
    INSTANCE_ID=$(get_instance_id $instance)
    if [ $ACTION == "create" ]; then
        if [ $INSTANCE_ID == "None" ]; then
            echo " Launching Instance: roboshop-$instance "
            INSTANCE_ID=$(aws ec2 run-instances \
               --image-id $AMI_ID \
               --instance-type t3.micro \
               --security-groups "roboshop-common" "roboshop-$instance" \
               --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="roboshop-$instance"}]" \
               --query 'Instances[0].InstanceId' \
               --output text
               )
               echo "launched Instance : $INSTANCE_ID"
      

         else
                echo "roboshop-$instance already running: $INSTANCE_ID"     
     
          fi 

          # update route 53 record #

          if [ $instance == "frontend" ]; then 
                    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                    --output text
                    )
                    R53_RECORD="$DOMAIN_NAME"

               else 
                    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
                    --output text 
                    )
                    R53_RECORD="$instance.$DOMAIN_NAME"
               fi  

               #####  updating R53 Record   ####
               aws route53 change-resource-record-sets \
               --hosted-zone-id $ZONE_ID \
               --change-batch '
                    {
                         "Comment": "Upate a record to new IP",
                         "Changes": [
                              {
                              "Action": "UPSERT",
                              "ResourceRecordSet": {
                                   "Name": "'$R53_RECORD'",
                                   "Type": "A",
                                   "TTL": 300,
                                   "ResourceRecords": [
                                        {
                                             "Value": "'$IP'"
                                        }
                                   ]
                              }
                              }
                         ]
                    }
               '  
               echo "updated R53 record for : $instance"

          else

               if [ $INSTANCE_ID == "None" ]; then
                  echo "$instance already destroyed ntng to do"

               else   
                     aws ec2 terminate-instances --instance-ids $INSTANCE_ID
                     echo "Terminating Instance: $instance"

               fi


          fi

done