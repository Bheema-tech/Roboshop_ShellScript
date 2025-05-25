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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

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
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installation of maven"
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
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the coder"
unzip  /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping the data to app directory"
mvn clean package &>>$LOG_FILE
VALIDATE $? "installing dependencies"
mv target/shipping-1.0.jar shipping.jar 
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copying shipping service filer"
systemctl daemon-reload
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "start the shipping service"
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enable the shipping service"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Install MySQL"

mysql -h mysql.bheemadevops.fun -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.bheemadevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.bheemadevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.bheemadevops.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE