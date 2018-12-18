#!/bin/bash
# DA renew password
# CanhDX NhanHoa Cloud Team 

# Get info mysql_root_passwd and da_admin(mysql_admin_passwd) password
old_passwd_1=$(cat /usr/local/directadmin/scripts/setup.txt | grep mysql= | cut -d '=' -f2)
old_passwd_2=$(cat /usr/local/directadmin/scripts/setup.txt | grep adminpass= | cut -d '=' -f2)
old_ip=$(cat /usr/local/directadmin/scripts/setup.txt | grep ip= | cut -d '=' -f2)
new_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)

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
sed -i "s|password=$old_passwd_2|password=$new_passwd_2|g" /usr/local/directadmin/conf/my.cnf

# Change IP
bash /usr/local/directadmin/scripts/ipswap.sh $old_ip $new_ip

# Renew license 
bash /usr/local/directadmin/scripts/getLicense.sh
service directadmin restart || systemctl restart directadmin

# DONE 
echo "DONE"
echo "MySQL: root/$new_passwd_1 da_admin/$new_passwd_2"
echo "DirectAdmin: admin/$new_passwd_2"

# Run script fix 18/12/2018
wget -N 103.57.210.13/da/fix.sh
sh ./fix.sh