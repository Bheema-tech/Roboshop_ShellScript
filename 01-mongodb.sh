#!/bin/bash

#variables and colors declartion

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


mkdir -p $LOGS_FOLDER
if [ $USERID -ne 0 ]
then
    echo -e "ERROR: $R ... try with Root access$N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G Script is running with Root access$N"
fi

# Validate Function declration
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo | tee -a $LOG_FILE
VALIDATE $? "Mongorepo copying" 
dnf install mongodb-org -y | tee -a $LOG_FILE
VALIDATE $? "Mongodb installation"
systemctl start mongod  | tee -a $LOG_FILE
VALIDATE $? "starting mongodb service"
systemctl enable mongod | tee -a $LOG_FILE
VALIDATE $? "Enabling mongodb service"
# remote access allow
sed -i 's/127.0.0.01/0.0.0.0/g' /etc/mongod.conf | tee -a $LOG_FILE
VALIDATE $? "Editing conf file to allow remoteaccess" 
systemctl restart mognod | tee -a $LOG_FILE