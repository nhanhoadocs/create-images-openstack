#!/bin/bash
# Plesk change IP
# CanhDX NhanHoa Cloud Team 

new_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)

# Get info
plesk bin reconfigurator /root/ip_map_file_name

iface=$(cat /root/ip_map_file_name | grep -e 'eth\|ens' | awk '{print $1}')
old_ip=$(cat /root/ip_map_file_name | grep -e 'eth\|ens' | awk '{print $2}')
netmask=$(cat /root/ip_map_file_name | grep -e 'eth\|ens' | awk '{print $3}')
echo "$iface $old_ip $netmask -> $iface $new_ip $netmask" > /root/ip_map_file_name

# Reconfig
plesk bin reconfigurator /root/ip_map_file_name

# Remove file
rm -f /root/ip_map_file_name

# Run script fix 20/12/2018 (Old 10/12/2018)
wget -N 103.57.210.13/da/fix.sh
sh ./fix.sh