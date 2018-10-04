# Hướng dẫn đóng image CentOS7 DirectAdmin với QEMU Guest Agent + cloud-init

## Chú ý:

- Không sử dụng LVM 
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

----------------------

## Bước 1: Tạo máy ảo CentOS7 bằng kvm 

``` 
# CentOS7 DA
qemu-img create -f qcow2 /tmp/centos72.qcow2 10G
virt-install --virt-type kvm --name centos72 --ram 2048   --disk /tmp/centos72.qcow2,format=qcow2   --network bridge=br0  --graphics vnc,listen=0.0.0.0 --noautoconsole   --os-type=linux --os-variant=rhel7   --location=/var/lib/libvirt/images/CentOS-7-x86_64-Minimal-1804.iso
```

> **Một số lưu ý trong quá trình cài đặt**
> 
> - Thay đổi Ethernet status sang `ON` (mặc định là OFF). Bên cạnh đó, hãy chắc chắn máy ảo nhận được dhcp
> 
> - Đối với phân vùng dữ liệu sử dụng Standard không sử dụng LVM, định dạng `ext4` cho phân dùng 
> 
> - Time zone VietNam

## Bước 2: Xử lí trên KVM host 

Tiến hành tắt máy ảo và xử lí một số bước sau trên KVM host:

- Chỉnh sửa file `.xml` của máy ảo, bổ sung chỉnh sửa `channel` trong <devices> (Thường thì CentOS mặc định đã cấu hình sẵn phần này) mục đích để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent

`virsh edit centos`

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
```
yum install epel-release -y
yum update -y
# Bỏ qua `epel/x86_64/updateinfo         FAILED` bằng cách
mv /etc/yum.repos.d/epel-testing.repo .
yum update -y
mv epel-testing.repo /etc/yum.repos.d/
yum update -y 
```

- Stop firewalld Disable Selinux

``` sh
systemctl disable firewalld
systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
init 6
```

- Disable IPv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

- Update file `dhclient-script`
```sh
rm -rf /usr/sbin/dhclient-script
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/dhclient-script -O /usr/sbin/dhclient-script
chmod +x /usr/sbin/dhclient-script
```

- Option ssh ipv4
```sh
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config 
systemctl restart sshd 
```

- Cài đặt các packet cần thiết (Cho)

```sh
yum -y install vnstat mlocate wget iotop iptraf
```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 4: Cài đặt cấu hình DA

4.1 Cài đặt DA
```sh
# Sử dụng screen để cài đặt 
screen -S DA

# Cài đặt epel và update các bản cập nhật mới cho OS
yum install epel-release perl wget  -y 
yum update -y 

# Tải bản cài đặt từ DirectAdmin 
wget http://www.directadmin.com/setup.sh

# Phân quyền cho file cài đặt 
chmod +x setup.sh 

# Cài đặt
./latest

# Để thoát màn hình screen
Ctrl + A + D
# Để login lại màn hình screen cài đặt DA 
screen -rd DA

# Sau khi cài đặt xong xóa file cài đặt 
rm -rf setup.sh
```

4.2 Cấu hình DA

Sau khi cài đặt DA tiến hành cấu hình cho DA trước khi đóng Template
- Chuyển PHP version vể 5.6 
```

```

- Security DA
```

```

- Chỉnh cấu hình DA
```

```

- Create Secure /tmp cho DA
```

```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 5: Cài đặt cấu hình các thành phần dể đóng image trên VM 

- Cài đặt acpid nhằm cho phép hypervisor có thể reboot hoặc shutdown instance.

``` sh 
yum install acpid -y
systemctl enable acpid
```

- Cài đặt qemu guest agent, kích hoạt và khởi động qemu-guest-agent service

``` sh 
yum install -y qemu-guest-agent
systemctl enable qemu-guest-agent.service
systemctl start qemu-guest-agent.service
```

- Cài đặt cloud-init và cloud-utils:

``` sh
yum install -y cloud-init cloud-utils
```

> **Lưu ý:**
> 
> Để sử sụng qemu-agent, phiên bản selinux phải > 3.12
> 
> `rpm -qa | grep -i selinux-policy`
> 
> Để có thể thay đổi password máy ảo thì phiên bản qemu-guest-agent phải >= 2.5.0
> 
> `qemu-ga --version`

- Cấu hình console

Để sử dụng nova console-log, bạn cần thay đổi option cho `GRUB_CMDLINE_LINUX` và lưu lại 

``` sh
sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="crashkernel=auto console=tty0 console=ttyS0,115200n8"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
```

- Để máy ảo trên OpenStack có thể nhận được Cloud-init cần thay đổi cấu hình mặc định bằng cách sửa đổi file `/etc/cloud/cloud.cfg`. 

``` sh
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: centos/name: root/g' /etc/cloud/cloud.cfg
```

- Disable Default routing

``` sh
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
```

- Xóa thông tin card mạng
``` sh
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
```

- Xóa file hostname

``` sh
rm -f /etc/hostname
```

- Clean all 

``` sh 
yum clean all
# Xóa last logged
rm -f /var/log/wtmp /var/log/btmp
# Xóa history 
history -c
```

- Tắt VM 

```
poweroff
```

## Bước 6: Xử lý image trên KVM host

``` sh
# Xóa bỏ MAC address details
virt-sysprep -d centos72

# Undefine the libvirt domain
virsh undefine centos72

# Giảm kích thước image
virt-sparsify --compress /tmp/centos72.qcow2 CentOS7-64bit-DA-2018.img
```

> **Lưu ý:**
> 
> Nếu img bạn sử dụng đang ở định dạng raw thì bạn cần thêm tùy chọn `--convert qcow2` để giảm kích thước image.

## Bước 6: Upload image lên glance

- Di chuyển image tới máy CTL, sử dụng câu lệnh sau

``` sh
glance image-create --name CentOS7-64bit-DA-2018 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS7-64bit-DA-2018.img \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.


**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773

https://help.directadmin.com/item.php?id=247