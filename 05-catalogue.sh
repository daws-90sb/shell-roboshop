#!/bin/bash



LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%y-%m-%d %H:%M:%S")


if [ $USERID -ne 0 ]; then 
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

dnf module disable nodejs -y &>> $LOGS_FILE
dnf module enable nodejs:20 -y &>> $LOGS_FILE
dnf install nodejs -y  &>> $LOGS_FILE
VALIDATE $? "Installing nodejs:20"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE 
    VALIDATE $? "Creating roboshop systemuser"
else 
    echo -e "sytem user roboshop already created .....$Y SKIPPING $N"
fi        

rm -rf /app
VALIDATE $? "removing existing code"

rm -rf /tmp/catalogue.zip
VALIDATE $? "removed catalogue zip"

mkdir -p /app  &>> $LOGS_FILE
VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Downloaded and extracted catalogue code"

npm install 
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added Mongo Repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Installed Mongodb Client"


