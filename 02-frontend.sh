#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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
dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disablement of nginx"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable of nginx20"
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installation of nodejs"
systemctl start nginx
VALIDATE $? "start the nginx service"
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enable the nginx service"
mkdir -p /app
VALIDATE $? "Directory creation" &>>$LOG_FILE
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "Restarting nginx"
