# CentOS Scripts Images
# NhanHoa Cloud365 Team
# 25/09/2018
# CentOS7 version 1804
# Using: curl -Lso- https://raw.githubusercontent.com/nhanhoacloud365/create-images-openstack/master/scripts_all/image-centos7.sh | bash

# Disable SElinux & Firewalld
systemctl disable firewalld
systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
init 6 

# Update 
yum install epel-release -y
yum update -y 

# Acpi install 
yum install acpid -y
systemctl enable acpid

# 
yum install qemu-guest-agent cloud-init cloud-utils -y

# Enable Qemu-agent
systemctl enable qemu-guest-agent.service
systemctl start qemu-guest-agent.service

# Sed 
sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="crashkernel=auto console=tty0 console=ttyS0,115200n8"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Cập nhật dhclient-scripts
rm /usr/sbin/dhclient-script
wget https://raw.githubusercontent.com/nhanhoacloud365/create-images-openstack/master/scripts_all/dhclient-script -O /usr/sbin/dhclient-script
chmod +x /usr/sbin/dhclient-script

# Cấu hình Cloud-init 
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: centos/name: root/g' /etc/cloud/cloud.cfg

# Disable Default routing 
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

# Xóa thông tin card mạng 
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0

# Xóa hostname 
rm -f /etc/hostname


# Tắt VM 
poweroff