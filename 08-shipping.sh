#!/bin/bash



LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

CARTID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%y-%m-%d %H:%M:%S")


if [ $CARTID -ne 0 ]; then 
    echo -e " $TIMESTAMP [ERROR] $R please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() { 
    if [ $1 -ne 0 ]; then
          echo -e " $TIMESTAMP [ERROR] $2.....$R FAILURE $N " | tee -a $LOGS_FILE
          exit 1
    else
          echo -e " $TIMESTAMP [INFO] $2.....$G SUCCESS $N " | tee -a $LOGS_FILE
    fi             

}


dnf install maven -y  &>> $LOGS_FILE
VALIDATE $?  "Installing Maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE 
    VALIDATE $? "Creating roboshop systemuser"
else 
    echo -e "sytem user roboshop already created .....$Y SKIPPING $N"
fi        

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/shipping.zip
VALIDATE $? "removed shipping zip"

mkdir -p /app  &>> $LOGS_FILE
VALIDATE $? "Creating App Directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
cd /app 
unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Downloaded and extracted shipping code"

mvn clean package  &>> $LOGS_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing mysql client"


useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

mkdir /app 




