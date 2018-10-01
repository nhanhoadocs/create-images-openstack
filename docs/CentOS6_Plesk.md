# Hướng dẫn đóng image CentOS6 Plesk với QEMU Guest Agent + cloud-init

## Chú ý:

- Không sử dụng LVM 
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

----------------------

## Bước 1: Tạo máy ảo CentOS6 bằng kvm 

``` 
# CentOS6 Blank
qemu-img create -f qcow2 /tmp/centos63.qcow2 10G
virt-install --virt-type kvm --name centos63 --ram 2048   --disk /tmp/centos63.qcow2,format=qcow2   --network bridge=br0  --graphics vnc,listen=0.0.0.0 --noautoconsole   --os-type=linux --os-variant=rhel7   --location=/var/lib/libvirt/images/CentOS-7-x86_64-Minimal-1804.iso
```

> **Một số lưu ý trong quá trình cài đặt**
> 
> - Thay đổi Ethernet status sang `ON` (mặc định là OFF). Bên cạnh đó, hãy chắc chắn máy ảo nhận được dhcp
> 
> - Đối với phân vùng dữ liệu sử dụng Standard không sử dụng LVM, định dạng `ext4` cho phân dùng /


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
```

- Stop firewalld Disable Selinux (Tùy trường hợp, Bản đang cài để nguyên toàn bộ ko disable)

``` sh
service iptables stop
chkconfig iptables off
iptables -F
iptables -X
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

- Cài đặt các packet cần thiết 

```sh
yum -y install vnstat mlocate wget iotop iptraf
# security tmp
echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab
```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 4: Cài đặt cấu hình các thành phần dể đóng image trên VM 

- Cấu hình network 

```
# Cấu hình interface tự động up khi boot 
sed -i 's|ONBOOT=no|ONBOOT=yes|g' /etc/sysconfig/network-scripts/ifcfg-eth0

# Xóa `HWADDR` và UUID trong config
# rm -f /etc/udev/rules.d/70-persistent-net.rules
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
```
- Cài đặt cloud-utils-growpart để resize đĩa cứng lần đầu boot

```
yum install cloud-utils-growpart dracut-modules-growroot cloud-init -y
```

-  Rebuild initrd file (Có thể mất 1-2p)

``` sh 
rpm -qa kernel | sed 's/^kernel-//'  | xargs -I {} dracut -f /boot/initramfs-{}.img {}
```

- Cấu hình grub để đẩy log ra console `vi /boot/grub/grub.conf`

``` sh 
Thay thế `rhgb quiet` bằng `console=tty0 console=ttyS0,115200n8`
```

- Để máy ảo trên OpenStack có thể nhận được Cloud-init cần thay đổi cấu hình mặc định bằng cách sửa đổi file `/etc/cloud/cloud.cfg`. 

``` sh
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: centos/name: root/g' /etc/cloud/cloud.cfg
```

- Để sau khi boot máy ảo có thể nhận đủ các NIC gắn vào

``` sh 
yum install netplug wget  -y
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/netplug_centos6 -O netplug
# Đưa file vào `/etc/netplug`
rm -rf /etc/netplug.d/netplug
mv netplug /etc/netplug.d/netplug
chmod +x /etc/netplug.d/netplug
```

- Disable Default routing

``` sh
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
```

- Disable sinh ra file `70-persistent-net.rules` (Tránh việc thay đổi label card mạng)

``` sh 
echo "#" > /lib/udev/rules.d/75-persistent-net-generator.rules
```

- Cài đặt, kích hoạt và khởi động qemu-guest-agent service

``` sh 
yum install qemu-guest-agent -y
chkconfig qemu-ga on
service qemu-ga start
```

> `qemu-ga --version`
> 
> `qemu-ga --version` Hiện Version của qemu trên centos6 là 0.12


- Clean all 

``` sh 
yum clean all
# Xóa last logged
rm -f /var/log/wtmp /var/log/btmp
# Xóa history 
history -c
```

- Tắt VM 

``` sh 
poweroff
```

## Bước 5: Xử lý image trên KVM host

``` sh
# Xóa bỏ MAC address details
virt-sysprep -d centos63

# Undefine the libvirt domain
virsh undefine centos63

# Giảm kích thước image
virt-sparsify --compress /tmp/centos63.qcow2 CentOS6-64bit-Plesk-2018.img
```

> **Lưu ý:**
> 
> Nếu img bạn sử dụng đang ở định dạng raw thì bạn cần thêm tùy chọn `--convert qcow2` để giảm kích thước image.

## Bước 6: Upload image lên glance

- Di chuyển image tới máy CTL, sử dụng câu lệnh sau

``` sh
glance image-create --name CentOS6-64bit-Plesk-2018 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS6-64bit-Plesk-2018.img \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.


**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773
