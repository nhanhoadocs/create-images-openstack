#!/bin/bash
# DA renew password
# CanhDX NhanHoa Cloud Team 

# Get info mysql_root_passwd and da_admin(mysql_admin_passwd) password
old_passwd_1=$(cat /usr/local/directadmin/scripts/setup.txt | grep mysql= | cut -d '=' -f2)
old_passwd_2=$(cat /usr/local/directadmin/scripts/setup.txt | grep adminpass= | cut -d '=' -f2)

# Input from cloud-init
# new_passwd_1=$1
# new_passwd_2=$2

# Input from random 
new_passwd_1=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
new_passwd_2=$(date +%s | sha256sum | base64 | head -c 10 ; echo)

# Change password
echo -e "$new_passwd_2\n$new_passwd_2" | passwd admin
mysqladmin --user=root --password=$old_passwd_1 password $new_passwd_1
mysqladmin --user=da_admin --password=$old_passwd_2 password $new_passwd_2

# Save info 
sed -i "s|mysql=$old_passwd_1|mysql=$new_passwd_1|g" /usr/local/directadmin/scripts/setup.txt
sed -i "s|adminpass=$old_passwd_2|adminpass=$new_passwd_2|g" /usr/local/directadmin/scripts/setup.txt
sed -i "s|passwd=$old_passwd_2|passwd=$new_passwd_2|g" /usr/local/directadmin/conf/mysql.conf

# Renew license 
bash /usr/local/directadmin/scripts/getLicense.sh
service directadmin restart || systemctl restart directadmin