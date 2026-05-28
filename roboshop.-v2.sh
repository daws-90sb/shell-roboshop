#!/bi/bash


AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0925237PNVPSE5X635V" # replace with your zone id
DOMAIN_NAME="daws-90sb.online" # replace with your domain id

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


### validation error ###
if [ $# -lt 2 ]; then
     echo -2 "$R ERROR :: Alteast 2 arguments required $N"
     echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
     exit 1
fi    


