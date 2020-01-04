# Hướng dẫn đóng image CentOS8 với QEMU Guest Agent + cloud-init

### Chú ý trong quá trình đóng images

- KVM host đã được cài đặt sẵn sàng. [Cài đặt Môi trường để đóng images](Prepare.md)
- Đã có file iso của CentOS8
- Sử dụng `Standard` với định dạng `ext4` cho phân vùng OS không sử dụng LVM.
- Sử dụng công cụ virt-manager hoặc webvirtcloud để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host
- Time zone VietNam
- RAM:2GB Disk:10GB CPU:2Core

----------------------

## Bước 1:Trên KVM host tạo máy ảo CentOS8

Reboot lại VM sau khi cài đặt hoàn tất

![](../images/centos8/centos8_001.png)
![](../images/centos8/centos8_002.png)
![](../images/centos8/centos8_003.png)
![](../images/centos8/centos8_004.png)
![](../images/centos8/centos8_005.png)
![](../images/centos8/centos8_006.png)
![](../images/centos8/centos8_007.png)
![](../images/centos8/centos8_008.png)
![](../images/centos8/centos8_009.png)
![](../images/centos8/centos8_010.png)
![](../images/centos8/centos8_011.png)
![](../images/centos8/centos8_012.png)
![](../images/centos8/centos8_013.png)
![](../images/centos8/centos8_014.png)
![](../images/centos8/centos8_015.png)
![](../images/centos8/centos8_016.png)
![](../images/centos8/centos8_017.png)
![](../images/centos8/centos8_018.png)
![](../images/centos8/centos8_019.png)


## Bước 2: Xử lí trên KVM host 

Tiến hành tắt máy ảo và xử lí một số bước sau trên KVM host:

- Chỉnh sửa file `.xml` của máy ảo, bổ sung chỉnh sửa `channel` trong <devices> (Thường thì CentOS mặc định đã cấu hình sẵn phần này) mục đích để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent

`virsh edit centos8`

với `centos*` là tên máy ảo

``` sh
...
<devices>
 <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
 </channel>
</devices>
...
```

## Bước 3: Cấu hình máy ảo và cài đặt các package

- Bật máy ảo lên

- Cài đặt epel-release & Update 
```sh 
dnf install epel-release -y
dnf update -y
```

- Stop firewalld Disable Selinux
``` sh
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
```

- Disable IPv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

- Đổi interface name từ `ens` về `eth`
```sh 
sed -i 's|GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"|GRUB_CMDLINE_LINUX="crashkernel=auto net.ifnames=0 biosdevname=0 rhgb quiet"|g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg 
rm -f /etc/sysconfig/network-scripts/ifcfg-ens3
```

- Cài đặt Chronyd 
```sh
dnf install chrony -y
sed -i 's|pool 2.centos.pool.ntp.org iburst|pool 103.101.161.201 iburst|g' /etc/chrony.conf
systemctl enable --now chronyd 
hwclock --systohc
```

- Cài đặt CMDlog
```sh 
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
```

- Bổ sung `LC_ALL=C`
```sh 
echo "export LC_ALL=C" >> ~/.bashrc
echo "export LC_ALL=C" >> /etc/skel/.bashrc
```

- Reboot lại máy 

- Đăng nhập cập nhật lại network config
```sh 
nmcli c modify "Wired connection 1" connection.id eth0
```

- Chỉnh sửa lại `eth0` config 
```sh 
>/etc/sysconfig/network-scripts/ifcfg-eth0 

cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-eth0 
TYPE=Ethernet
BOOTPROTO=dhcp
NAME=eth0
ONBOOT=yes
EOF

systemctl restart NetworkManager
```

- Tắt máy và tiến hành Snapshot

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

### Cài đặt app (nếu có) 

- [DA](Install_DA.md)
- [Plesk](Install_Plesk)
- [WHM](Install_WHM)

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 4: Cài đặt cấu hình các thành phần dể đóng image trên VM 

- Khởi động lại VM và tiến hành cài đặt các package, tools của OPS

- Cài đặt acpid nhằm cho phép hypervisor có thể reboot hoặc shutdown instance.

``` sh 
dnf install acpid -y
systemctl enable --now acpid
```

- Cài đặt packages cần thiết
```sh 
dnf -y install vim bash-completion cloud-init qemu-guest-agent cloud-utils-growpart 
systemctl enable --now qemu-guest-agent.service
```

- Cấu hình console để sử dụng nova console-log
``` sh
sed -i 's|GRUB_CMDLINE_LINUX="crashkernel=auto net.ifnames=0 biosdevname=0 rhgb quiet"|GRUB_CMDLINE_LINUX="crashkernel=auto net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0,115200n8"|g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg 
```

- Để máy ảo trên OpenStack có thể nhận được Cloud-init cần thay đổi cấu hình mặc định bằng cách sửa đổi file `/etc/cloud/cloud.cfg`. 

``` sh
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: cloud-user/name: root/g' /etc/cloud/cloud.cfg
```

- Disable the zeroconf route
``` sh
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
```

- Xóa thông tin card mạng
``` sh
chattr -i /etc/sysconfig/network-scripts/ifcfg-eth0
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
chattr -i /etc/sysconfig/network-scripts/ifcfg-eth0:1
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0:1
```

- Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:

```sh 
cat << EOF >> /etc/rc.local
for iface in \$(ip -o link | cut -d: -f2 | tr -d ' ' | grep ^eth)
do
   test -f /etc/sysconfig/network-scripts/ifcfg-\$iface
   if [ \$? -ne 0 ]
   then
       touch /etc/sysconfig/network-scripts/ifcfg-\$iface
       echo -e "DEVICE=\$iface\nBOOTPROTO=dhcp\nONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-\$iface
       ifup \$iface
   fi
done
EOF
```

- Thêm quyền thực thi cho file `/etc/rc.d/rc.local`
```sh
chmod +x /etc/rc.d/rc.local
```

- Xóa file hostname

``` sh
rm -f /etc/hostname
```

- Clean all 

``` sh 
dnf clean all
# Xóa last logged
rm -f /var/log/wtmp /var/log/btmp
# Xóa history 
rm -f /root/.bash_history
> /var/log/cmdlog.log
history -c
```

- Tắt VM 
```
poweroff
```

## Bước 5: Xử lý image trên KVM host

``` sh
# Xóa bỏ MAC address details
virt-sysprep -d OPS_Template_CentOS8

# Giảm kích thước image
virt-sparsify --compress /var/lib/libvirt/images/OPS_Template_CentOS8.qcow2 CentOS8-DA.qcow2
```

## Bước 6: Đối với các Images cần chỉnh sửa thêm có thể chui vào sửa config bằng cách sau 

```sh 
export LIBGUESTFS_BACKEND=direct
guestfish --rw -a CentOS8-DA.qcow2

><fs> run
><fs> mount /dev/sda1 /
><fs> touch /var/spool/cron/root
><fs> vi /var/spool/cron/root
    0 19 * * * /bin/sh /usr/local/directadmin/scripts/local.sh  >> /dev/null 2>&1
><fs> chmod 0755 /var/spool/cron/root
><fs> umount / 
><fs> exit
```

## Bước 7: Upload image lên glance

- Di chuyển image tới máy CTL, sử dụng câu lệnh sau
``` sh
glance image-create --name CentOS8.qcow2 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS8.qcow2 \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.


**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773

https://computingforgeeks.com/how-to-create-centos-8-kvm-image-template-for-openstack/