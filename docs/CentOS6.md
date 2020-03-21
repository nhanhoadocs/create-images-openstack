# Hướng dẫn đóng image CentOS6 với QEMU Guest Agent + cloud-init

## Chú ý trong quá trình đóng images

- KVM host đã được cài đặt sẵn sàng. [Cài đặt Môi trường để đóng images](Prepare.md)
- Đã có file iso của CentOS6
- Sử dụng `Standard` với định dạng `ext4` cho phân vùng OS không sử dụng LVM.
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host
- Time zone VietNam

----------------------

## Bước 1:Trên KVM host tạo máy ảo CentOS6

- Đăng nhập ssh vào Node KVM bật `virt-manager`
```sh
virt-manager
```

- Trên Virt-manager thực hiện các step sau để cài OS

Click chuột phải vào `QEMU/KVM` chọn `Details`

![](../images/centos/centos6_install_01.png)

Click vào tab `Storage` create một images mới

![](../images/centos/centos6_install_02.png)

Set tên và dung lượng cho images này là với định dạng là `.qcow2`

![](../images/centos/centos6_install_03.png)

Quay lại màn hình chính của Virt-manager chọn create VM mới

![](../images/centos/centos6_install_04.png)

Chọn boot từ file ISO

![](../images/centos/centos6_install_05.png)

Trỏ đường dẫn đến file ISO 

![](../images/centos/centos6_install_06.png)

![](../images/centos/centos6_install_07.png)

![](../images/centos/centos6_install_08.png)

Cấu hình RAM và CPU cho VM 

![](../images/centos/centos6_install_09.png)

Ở đây chúng ta sẽ chọn images `centos6.qcow2` đã được tạo

![](../images/centos/centos6_install_10.png)

![](../images/centos/centos6_install_11.png)

![](../images/centos/centos6_install_12.png)

Đặt tên cho VM, click vào `Customize...` để bổ sung các cấu hình khác

![](../images/centos/centos6_install_13.png)

Cấu hình cho CPU

![](../images/centos/centos6_install_14.png)

Cấu hình boot, chỉnh lại menu boot để boot ISO cài đặt OS

![](../images/centos/centos6_install_15.png)

Cấu hình lại file ISO

![](../images/centos/centos6_install_16.png)

![](../images/centos/centos6_install_17.png)

![](../images/centos/centos6_install_18.png)

![](../images/centos/centos6_install_19.png)

Cấu hình NIC mode `virtio`

![](../images/centos/centos6_install_20.png)

Kết thúc quá trình cấu hình, bắt đầu quá trình cài đặt. 

![](../images/centos/centos6_install_21.png)

![](../images/centos/centos6_install_22.png)

Bỏ qua quá trình check 

![](../images/centos/centos6_install_23.png)

![](../images/centos/centos6_install_24.png)

Cấu hình ngôn ngữ chọn `English(English)`

![](../images/centos/centos6_install_25.png)

Cấu hình language keyboard chọn `U.S English`

![](../images/centos/centos6_install_26.png)

Chọn `Basic Storage Devices`

![](../images/centos/centos6_install_27.png)

Confirm xóa toàn bộ dữ liệu trên disk cài đặt OS

![](../images/centos/centos6_install_28.png)

Cấu hình network

![](../images/centos/centos6_install_29.png)

![](../images/centos/centos6_install_30.png)

Enable connect automatically (Cho phép Interface có thể nhận được IP khi boot máy)

![](../images/centos/centos6_install_31.png)

![](../images/centos/centos6_install_32.png)

Cấu hình time zone Asia/Ho_Chi_Minh 

![](../images/centos/centos6_install_33.png)

Cấu hình root password cho VM 

![](../images/centos/centos6_install_34.png)

Chọn `Create Custom Layout` để cấu hình phân vùng disk cài OS

![](../images/centos/centos6_install_35.png)

Chọn phân vùng free disk và `Create`

![](../images/centos/centos6_install_36.png)

Chọn cấu hình phân vùng disk theo `Standard Partition` 

![](../images/centos/centos6_install_37.png)

Cấu hình toàn bộ phân vùng trống của disk mount vào `/` với định dạng `ext4`

![](../images/centos/centos6_install_38.png)

![](../images/centos/centos6_install_39.png)

Confirm quá trình phân vùng lại ổ đĩa để cài OS

![](../images/centos/centos6_install_40.png)

![](../images/centos/centos6_install_41.png)

![](../images/centos/centos6_install_42.png)

Tiến hành xác nhận cài đặt OS

![](../images/centos/centos6_install_43.png)

![](../images/centos/centos6_install_44.png)

![](../images/centos/centos6_install_45.png)

## Bước 2: Xử lí trên KVM host 

Tiến hành tắt máy ảo và xử lí một số bước sau trên KVM host:

- Chỉnh sửa file `.xml` của máy ảo

```sh 
virsh edit centos6
```

> Với `centos6` là tên máy ảo

Bổ sung hoặc chỉnh sửa `channel` trong <devices>  mục đích để HOST KVM có thể giao tiếp với máy ảo qua qemu-guest-agent

``` sh
# Nội dung chỉnh sửa
...
<devices>
 <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
 </channel>
 ...
</devices>
...
```

## Bước 3: Cấu hình máy ảo và cài đặt các package (Thao tác trên VM CentOS6)

- Bật máy ảo lên

- Disable IPv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

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

- Cài đặt các packet cần thiết 

```sh
yum -y install wget vim 
```

- Cài đặt CMDlog
```sh 
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
```

- Cài đặt Chronyd 
```sh
yum install chrony -y
sed -i 's|server 0.rhel.pool.ntp.org iburst|pool 103.101.161.201 iburst|g' /etc/chrony.conf
chkconfig chronyd on 
service chronyd start
hwclock --systohc
```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

- Shutdown VM 

![](../images/kvm/shutdown.png)

- Tiến hành truy cập tab `Snapshot` để snapshot

![](../images/kvm/snap.png)

### Cài đặt app (nếu có) 

- [DA](Install_DA.md)
- [Plesk](Install_Plesk)
- [WHM](Install_WHM)

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

## Bước 4: Cài đặt cấu hình các thành phần dể đóng image trên VM 

- Start lại và ssh vào VM 
```sh 
ssh root@<ip_VM>
```

- Cấu hình network 

```
# Cấu hình interface tự động up khi boot 
sed -i 's|ONBOOT=no|ONBOOT=yes|g' /etc/sysconfig/network-scripts/ifcfg-eth0

# Xóa `HWADDR` và UUID trong config
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

- Cấu hình grub để đẩy log ra console

``` sh 
sed -Ei "s/rhgb/console=tty0/g" /boot/grub/grub.conf
sed -Ei "s/quiet/console=ttyS0,115200n8/g" /boot/grub/grub.conf
```

- Để máy ảo trên OpenStack có thể nhận được Cloud-init cần thay đổi cấu hình mặc định bằng cách sửa đổi file `/etc/cloud/cloud.cfg`. 

``` sh
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: centos/name: root/g' /etc/cloud/cloud.cfg
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


- Disable Default routing (để VM có thể nhận metadata từ Cloud-init nhanh hơn)

``` sh
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
```

- Xóa nội dung `75-persistent-net-generator.rules` (Tránh việc thay đổi label card mạng)

``` sh 
echo "" > /lib/udev/rules.d/75-persistent-net-generator.rules
```

- Cài đặt, kích hoạt và khởi động qemu-guest-agent service

``` sh 
yum install qemu-guest-agent -y
chkconfig qemu-ga on
service qemu-ga start
```

> `qemu-ga --version` Hiện Version của qemu trên centos6 là 0.12
> 
> `service qemu-ga status` Chắc chắn qemu-ga running OK

- Đảm bảo interface eth0 có thể nhận DHCP (Remove config static IP của VM đóng template)
```
cat << EOF >> /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
IPV4_FAILURE_FATAL=yes
NAME="System eth0"
EOF
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

``` sh 
poweroff
```

## Bước 5: Xử lý image trên KVM host

``` sh
# Xóa bỏ MAC address details
virt-sysprep -d centos6

# Giảm kích thước image
virt-sparsify --compress /var/lib/libvirt/images/centos6.qcow2 CentOS6-64bit-2018.img
```

## Bước 6: Upload image lên glance

- Copy Images sang Node Controller
```sh
scp CentOS6-64bit-2018.img root@<controller_host>:/root/
```

- Đăng nhập vào Node Controller sử dụng câu lệnh sau để Upload Images

``` sh
glance image-create --name CentOS6-64bit-2018 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS6-64bit-2018.img \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.


**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773
