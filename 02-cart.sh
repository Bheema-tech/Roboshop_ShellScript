#!/bin/bash
START_TIME=$(date +%s)
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
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disablement of nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable of nodejs20"
dnf install nodejs -y &>>$LOG_FILE
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
cd /app
rm -rf /app/*   
#when we run multiple times, we should not get error, before copying the data to app directopry, better to delete the existing one
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the coder"
unzip  /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzipping the data to app directory"
npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "copying cart service filer"
systemctl daemon-reload
systemctl start cart &>>$LOG_FILE
VALIDATE $? "start the cart service"
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enable the cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE