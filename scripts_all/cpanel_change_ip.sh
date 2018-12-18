#!/bin/bash
# Cpanel change IP
# CanhDX NhanHoa Cloud Team 

# Get info
NEW_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
OLD_IP=$(cat /usr/local/apache/conf/httpd.conf | grep VirtualHost  | head -n 1 | awk '{print $2}' | cut -d  ':' -f1)

# Sed info
sed -Ei "s/$OLD_IP/$NEW_IP/g" /usr/local/apache/conf/httpd.conf
sed -Ei "s/$OLD_IP/$NEW_IP/g" /etc/wwwacct.conf
sed -Ei "s/$OLD_IP/$NEW_IP/g" /etc/hosts
sed -Ei "s/$OLD_IP/$NEW_IP/g" /var/cpanel/mainip

# Restart Service 
service named restart || systemctl restart named
service httpd restart || systemctl restart httpd
