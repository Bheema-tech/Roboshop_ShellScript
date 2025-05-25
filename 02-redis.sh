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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "redis Disable"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "redis enable 7 version"
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "redis installation"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting redis service"
systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling redis service"
# remote access allow
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Editing conf file to allow remoteaccess" 
systemctl restart redis | &>>$LOG_FILE
VALIDATE $? "redis service restarted" 