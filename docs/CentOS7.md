# Hướng dẫn đóng image CentOS7 với QEMU Guest Agent + cloud-init

### Chú ý trong quá trình đóng images

- KVM host đã được cài đặt sẵn sàng. [Cài đặt Môi trường để đóng images](Prepare.md)
- Đã có file iso của CentOS7
- Sử dụng `Standard` với định dạng `ext4` cho phân vùng OS không sử dụng LVM.
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host
- Time zone VietNam

----------------------

## Bước 1:Trên KVM host tạo máy ảo CentOS7

- Đăng nhập ssh vào Node KVM bật `virt-manager`
```sh
virt-manager
```

- Trên Virt-manager thực hiện các step sau để cài OS

Click chuột phải vào `QEMU/KVM` chọn `Details`

![](../images/centos7/centos7_install_01.png)

Click vào tab `Storage` create một images mới

![](../images/centos7/centos7_install_02.png)

Set tên và dung lượng cho images này là với định dạng là `.qcow2`

![](../images/centos7/centos7_install_03.png)

Quay lại màn hình chính của Virt-manager chọn create VM mới

![](../images/centos7/centos7_install_04.png)

Chọn boot từ file ISO

![](../images/centos7/centos7_install_05.png)


Trỏ đường dẫn đến file ISO 

![](../images/centos7/centos7_install_06.png)

![](../images/centos7/centos7_install_07.png)

Cấu hình RAM và CPU cho VM 

![](../images/centos7/centos7_install_08.png)

Ở đây chúng ta sẽ chọn images `centos6.qcow2` đã được tạo

![](../images/centos7/centos7_install_09.png)

![](../images/centos7/centos7_install_10.png)

![](../images/centos7/centos7_install_11.png)

Đặt tên cho VM, click vào `Customize...` để bổ sung các cấu hình khác

![](../images/centos7/centos7_install_12.png)


Cấu hình cho CPU

![](../images/centos7/centos7_install_13.png)

Cấu hình boot, chỉnh lại menu boot để boot ISO cài đặt OS

![](../images/centos7/centos7_install_14.png)

Cấu hình lại file ISO

![](../images/centos7/centos7_install_15.png)

![](../images/centos7/centos7_install_16.png)

![](../images/centos7/centos7_install_17.png)

![](../images/centos7/centos7_install_18.png)

Cấu hình NIC mode `virtio` và  bắt đầu quá trình cài đặt. 

![](../images/centos7/centos7_install_19.png)

Chọn `Install CentOS7` để tiến hành cài đặt 

![](../images/centos7/centos7_install_20.png)


Cấu hình ngôn ngữ chọn `English(English)`

![](../images/centos7/centos7_install_21.png)

Cấu hình timezone về Ho_Chi_Minh

![](../images/centos7/centos7_install_22.png)

![](../images/centos7/centos7_install_23.png)

Cấu hình disk để cài đặt 

![](../images/centos7/centos7_install_24.png)

![](../images/centos7/centos7_install_25.png)

Chọn `Standard Partition` cho ổ disk 

![](../images/centos7/centos7_install_26.png)

Cấu hình mount point `/` cho toàn bộ disk

![](../images/centos7/centos7_install_27.png)

Định dạng lại `ext4` cho phân vùng

![](../images/centos7/centos7_install_28.png)

![](../images/centos7/centos7_install_29.png)

Kết thúc quá trình cấu hình disk 

![](../images/centos7/centos7_install_30.png)

Confirm quá trình chia lại partition cho disk 

![](../images/centos7/centos7_install_31.png)

Cấu hình network 

![](../images/centos7/centos7_install_32.png)

Turn on network cho interface và set hostname 

![](../images/centos7/centos7_install_33.png)

Kết thúc cấu hình, bắt đầu quá trình cài đặt OS

![](../images/centos7/centos7_install_34.png)

Setup passwd cho root

![](../images/centos7/centos7_install_35.png)

![](../images/centos7/centos7_install_36.png)

Reboot lại VM sau khi cài đặt hoàn tất
![](../images/centos7/centos7_install_37.png)

## Bước 2: Xử lí trên KVM host 

Tiến hành tắt máy ảo và xử lí một số bước sau trên KVM host:

- Chỉnh sửa file `.xml` của máy ảo, bổ sung chỉnh sửa `channel` trong <devices> (Thường thì CentOS mặc định đã cấu hình sẵn phần này) mục đích để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent

`virsh edit centos7.0`

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
```

- Disable IPv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

- Update file `dhclient-script`
```sh
yum install wget -y
rm -rf /usr/sbin/dhclient-script
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/dhclient-script -O /usr/sbin/dhclient-script
chmod +x /usr/sbin/dhclient-script
```

- Option ssh ipv4
```sh
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config 
systemctl restart sshd 
```

- Cài đặt CMDlog
```sh 
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
```

- Cài đặt Chronyd 
```sh
yum install chrony -y
sed -i 's|server 1.centos.pool.ntp.org iburst|server 103.101.161.201 iburst|g' /etc/chrony.conf
systemctl enable --now chronyd 
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

- Thêm quyền thực thi cho file `/etc/rc.local`
```sh
chmod +x /etc/rc.local 
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
virt-sysprep -d OPS_Template_CentOS7

# Giảm kích thước image
virt-sparsify --compress /var/lib/libvirt/images/OPS_Template_CentOS7.qcow2 CentOS7.qcow2
```


## Bước 6: Upload image lên glance

- Copy Images sang Node Controller
```sh
scp CentOS7.qcow2 root@<controller_host>:/root/
```

- Di chuyển image tới máy CTL, sử dụng câu lệnh sau

```sh
glance image-create --name CentOS7.qcow2 \
--disk-format qcow2 \
--container-format bare \
--file /root/CentOS7.qcow2 \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Image đã sẵn sàng để launch máy ảo.


**Link tham khảo**

http://openstack-xenserver.readthedocs.io/en/latest/24-create-kvm-centos-7-image.html

https://docs.openstack.org/image-guide/centos-image.html

https://access.redhat.com/solutions/732773