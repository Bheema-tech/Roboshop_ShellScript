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
dnf module disable nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Disablement of nodejs"
dnf module enable nodejs:20 -y | tee -a $LOG_FILE
VALIDATE $? "enable of nodejs20"
dnf install nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Installation of nodejs"
mkdir -p /app
VALIDATE $? "Directory creation"
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
   echo "user already created.. nothing to do"
fi
cut
cd /app
rm -rf /app/*   #when we run multiple times, we should not get error, before copying the data to app directopry, better to delete the existing one
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the coder"
unzip  /tmp/catalogue.zip | tee -a $LOG_FILE
VALIDATE $? "unzipping the data to app directory"
npm install | tee -a $LOG_FILE
VALIDATE $? "installing dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service | tee -a $LOG_FILE
VALIDATE $? "copying catalogue service filer"
systemctl daemon-relolad
systemctl start catalogue | tee -a $LOG_FILE
VALIDATE $? "start the catalogue service"
systemctl enable catalogue | tee -a $LOG_FILE
VALIDATE $? "enable the catalogue service"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  | tee -a $LOG_FILE
#where mongo.repo located?  always keep better full source 
VALIDATE $? "copying mongo repo"
dnf install mongodb-mongosh -y  | tee -a $LOG_FILE
VALIDATE $? "mongodsh client installation"
STATUS=$(mongosh --host mongodb.bheemadevops.fun --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.bheemadevops.fun </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi