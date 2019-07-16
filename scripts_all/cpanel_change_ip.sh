#!/bin/bash
# WHM/Cpanel change IP
# CanhDX NhanHoa Cloud Team 

# Get info
NEW_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
OLD_IP=$(cat /usr/local/apache/conf/httpd.conf | grep VirtualHost  | head -n 1 | awk '{print $2}' | cut -d  ':' -f1)
mysql_old_passwd=$(cat /root/.my.cnf | grep password | cut -d '=' -f2 |  tr -d '"')

# Input from cloud-init
# mysql_new_passwd=$1

# Input from random 
mysql_new_passwd=$(date +%s | sha256sum | base64 | head -c 10 ; echo)

# Sed info
sed -Ei "s/$OLD_IP/$NEW_IP/g" /usr/local/apache/conf/httpd.conf
sed -Ei "s/$OLD_IP/$NEW_IP/g" /etc/wwwacct.conf
sed -Ei "s/$OLD_IP/$NEW_IP/g" /etc/hosts
sed -Ei "s/$OLD_IP/$NEW_IP/g" /var/cpanel/mainip

# Change MySQL root password 
mysqladmin --user=root --password=$mysql_old_passwd password $mysql_new_passwd

# Save mysql info 
sed -Ei "s/$mysql_old_passwd/$mysql_new_passwd/g"  /root/.my.cnf 

# Restart Service 
service named restart || systemctl restart named
service httpd restart || systemctl restart httpd
