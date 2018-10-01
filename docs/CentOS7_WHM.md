# Hướng dẫn đóng image CentOS7-WHM với QEMU Guest Agent + cloud-init

## Chú ý:

- Không sử dụng LVM 
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

----------------------

## Bước 1: Tạo máy ảo CentOS7 bằng kvm 

``` 
# CentOS7 Blank
qemu-img create -f qcow2 /tmp/centos73.qcow2 10G
virt-install --virt-type kvm --name centos73 --ram 2048   --disk /tmp/centos73.qcow2,format=qcow2   --network bridge=br0  --graphics vnc,listen=0.0.0.0 --noautoconsole   --os-type=linux --os-variant=rhel7   --location=/var/lib/libvirt/images/CentOS-7-x86_64-Minimal-1804.iso
```

> **Một số lưu ý trong quá trình cài đặt**
> 
> - Thay đổi Ethernet status sang `ON` (mặc định là OFF). Bên cạnh đó, hãy chắc chắn máy ảo nhận được dhcp
> 
> - Đối với phân vùng dữ liệu sử dụng Standard không sử dụng LVM, định dạng `ext4` cho phân dùng /


## Bước 2: Xử lí trên KVM host 

Tiến hành tắt máy ảo và xử lí một số bước sau trên KVM host:

- Chỉnh sửa file `.xml` của máy ảo, bổ sung thêm channel trong <devices> (Thường thì CentOS mặc định đã cấu hình sẵn phần này) mục đích để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent

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

- Stop firewalld Disable Selinux

``` sh
systemctl disable firewalld
systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
init 6
```

- Update file `dhclient-script`
```sh
rm -rf /usr/sbin/dhclient-script
wget ... -O /usr/sbin/dhclient-script
chmod +x /usr/sbin/dhclient-script
```

- Cài đặt epel-release & Update 
```
yum install epel-release -y
yum update -y
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

## Cài đặt WHM

``` sh
# Cài đặt các requirement packet 
yum install curl perl -y 

# Tải bản cài đặt về 
curl -o latest -L https://securedownloads.cpanel.net/latest

# Phân quyền cho file cài đặt 
chmod +x latest

# Cài đặt
./latest
```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 4: Cài đặt cấu hình các thành phần dể đóng image trên VM 

- Xóa file cài đặt 

``` sh 
rm -rf latest installer.lock
```

- Cài đặt acpid nhằm cho phép hypervisor có thể reboot hoặc shutdown instance.

``` sh 
yum install acpid -y
systemctl enable acpid
```

- Cài đặt qemu guest agent, cloud-init và cloud-utils:

``` sh
yum install qemu-guest-agent cloud-init cloud-utils -y
```

- Kích hoạt và khởi động qemu-guest-agent service

``` sh 
systemctl enable qemu-guest-agent.service
systemctl start qemu-guest-agent.service
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

- Tắt VM 

```
poweroff
```

## Bước 5: Xử lý image trên KVM host

``` sh
# Xóa bỏ MAC address details
virt-sysprep -d centos73

# Undefine the libvirt domain
virsh undefine centos73

# Giảm kích thước image
virt-sparsify --compress /tmp/centos73.qcow2 CentOS7-64bit-WHM-2018.img
```

> **Lưu ý:**
> 
> Nếu img bạn sử dụng đang ở định dạng raw thì bạn cần thêm tùy chọn `--convert qcow2` để giảm kích thước image.

## Bước 6: Upload image lên glance

- Di chuyển image tới máy CTL, sử dụng câu lệnh sau

``` sh
glance image-create --name CentOS7-64bit-WHM-2018 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS7-64bit-WHM-2018.img \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.

**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773
