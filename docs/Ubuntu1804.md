# Hướng dẫn đóng image Ubuntu 18.04 với cloud-init và QEMU Guest Agent (không dùng LVM)

## Chú ý:

- Hướng dẫn này dành cho các image không sử dụng LVM
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- OS cài đặt KVM là Ubuntu 18.04
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

----------------------

## Bước 1: Tạo máy ảo bằng virt-manager

## 1. Trên Host KVM
### 1.1. Tạo file disk máy ảo và cài đặt OS

 - Tạo file disk máy ảo
```sh
qemu-img create -f qcow2 /var/lib/libvirt/images/u18.qcow2  10G
```

 - Tạo máy ảo với tool `Virt-Manager`. Import file disk máy ảo. 
 
![u18](../images/ubuntu18/u18-00.png) 

 - Chọn *OS Type* : `Linux` , *Version* : `Ubuntu 17.04`, Chọn *Broswer* tới đường dẫn của file disk.
 
![u18](../images/ubuntu18/u18-01.png) 

 - Chọn file disk tại thư mục *images*
 
![u18](../images/ubuntu18/u18-02.png) 

 - Chọn dung lượng RAM và CPU 
 
![u18](../images/ubuntu18/u18-03.png) 

 - Đặt tên và tích vào dòng `Customize configuration before install`. Sau đó chọn *Finish*
 
![u18](../images/ubuntu18/u18-04.png) 

 - Chỉnh sửa mode của card mạng thành `virtio`
 
![u18](../images/ubuntu18/u18-05.png) 

 - Mount file ISO bằng cách thêm CDROM. Chọn *Add Hardware* => *Storage* => *Manage*, sau đó chọn file iso Ubuntu Server 18.04. Chú ý chọn *Device type* là `CDROM device`.
 
![u18](../images/ubuntu18/u18-08.png) 

 - Tại thư mục `iso`, chọn file iso Ubuntu server 18.04
 
![u18](../images/ubuntu18/u18-06.png) 

 - Chỉnh sửa Boot Option, chọn boot từ CDROM đầu tiên để cài đặt từ file ISO.
 
![u18](../images/ubuntu18/u18-09.png) 

 - Sau đó chọn *Begin Installation* để bắt đầu cài đặt 
 
![u18](../images/ubuntu18/u18-10.png) 

 - Chọn ngôn ngữ là *English*, sau đó ấn `ENTER`
 
![u18](../images/ubuntu18/u18-11.png) 

 - Chọn *Layout* và *Variant* là `English`, chọn `Done` và ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-12.png) 

 - Chọn `Install Ubuntu` và ấn `ENTER`
 
![u18](../images/ubuntu18/u18-13.png) 

 - Để card mạng sử dụng DHCP. Chọn `Done` và ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-14.png) 

 - Chọn không dùng Proxy. Chọn `Done` và ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-15.png) 

 - Chọn mirror Ubuntu mặc định. Chọn `Done` và ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-16.png) 

 - Chọn cài đặt Disk *KHÔNG DÙNG LVM*. Ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-17.png) 

 - Cài đặt sử dụng ổ vda. Ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-18.png) 

 - Chỉnh sửa lại cấu hình ổ cứng (nếu cần), sau đó chọn `DONE`.
 
![u18](../images/ubuntu18/u18-19.png) 

 - `Continue` để confirm và tiếp tục cài đặt.
 
![u18](../images/ubuntu18/u18-20.png) 

 - Điền các thông tin cho máy ảo. User mặc định được sử dụng là *ubuntu*.
 
![u18](../images/ubuntu18/u18-21.png) 

 - Không chọn option nào, kéo xuống chọn `Done` và ấn `ENTER`.
 
![u18](../images/ubuntu18/u18-22.png) 

 - Bắt đầu thực hiện cài đặt.
 
![u18](../images/ubuntu18/u18-23.png) 

 - Sau khi cài đặt xong chọn *Reboot Now* để thực hiện reboot. 
 
![u18](../images/ubuntu18/u18-24.png) 

 - Shutdown máy để thực hiện remove CDROM
 
![u18](../images/ubuntu18/u18-25.png) 

 - Remove CDROM
 
![u18](../images/ubuntu18/u18-26.png) 


## Bước 2 : Tắt máy ảo, xử lí trên KVM host

- Chỉnh sửa file `.xml` của máy ảo, bổ sung thêm channel trong <devices> (để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent), sau đó save lại

`virsh edit ubuntu16`

với `ubuntu16` là tên máy ảo

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
> Nếu đã tồn tại `channel` đổi port channel này về `port='2'` và add channel bình thường

![](../images/ubuntu12/u12_install_54.png)


## 2. Thực hiện trên máy ảo cài đặt các dịch vụ cần thiết 

### 2.1. Setup môi trường 

Bật máy ảo lên, truy cập vào máy ảo. Lưu ý với lần đầu boot, bạn phải sử dụng tài khoản `ubuntu` tạo trong quá trình cài os, chuyển đổi nó sang tài khoản root để sử dụng.

Cấu hình cho phép login root và xóa user `ubuntu` chỉnh `/etc/ssh/sshd_config`
```sh
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'g /etc/ssh/sshd_config
service sshd restart
```

Đặt passwd cho root
```sh
sudo su 
# Đặt passwd cho root user
passwd
Enter new UNIX password: <root_passwd>
Retype new UNIX password: <root_passwd>
```

Restart sshd
```sh
sudo service ssh restart
```

Disable firewalld 
```sh
sudo apt-get install ufw -y
sudo ufw disable
sudo stop disable
```

Logout hẳn ra khỏi VM 
```sh 
logout 
```

Login lại bằng user `root` và xóa user `ubuntu`
```sh
userdel ubuntu
rm -rf /home/ubuntu
```

Đổi timezone về `Asia/Ho_Chi_Minh`
```sh
dpkg-reconfigure tzdata
```

Bổ sung env locale 
```sh 
echo "export LC_ALL=C" >>  ~/.bashrc
```

Disable ipv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
```
> Output: 1: OK, 0: NotOK

Update 
```sh
sudo apt-get update -y 
sudo apt-get upgrade -y 
sudo apt-get dist-upgrade -y
sudo apt-get autoremove 
```

Kiểm tra swap file 
```sh 
root@ubuntu:~# cat /proc/swaps
Filename				Type		Size	Used	Priority
/swap.img                               file		2023420	0	-2
```

Xóa swap 
```sh 
swapoff -a
rm -rf /swap.img
```

Xóa cấu hình swap file trong file `/etc/fstab`
```sh 
sed -Ei '/swap.img/d' /etc/fstab
```
> Kiểm tra 
```sh
root@ubuntu:~# free -m 
              total        used        free      shared  buff/cache   available
Mem:           1993         127         699           1        1166        1691
Swap:             0           0           0
```

Cấu hình để instance báo log ra console và đổi name Card mạng về eth* thay vì ens, eno
```sh
sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 console=tty1 console=ttyS0"|g' /etc/default/grub
update-grub
```

Cấu hình network sử dụng ifupdown thay vì netplan

 - Cài đặt service ifupdown 
```sh
apt-get install ifupdown -y
```

 - Disable netplan
```sh
cat << EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF

rm -rf /etc/netplan50-cloud-init.yaml
```

 - Tạo file interface
```sh
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF
```

Reboot lại Server kiểm tra `eth0`, network

Tiến hành SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

- Shutdown VM 

![](../images/kvm/shutdown.png)

- Tiến hành truy cập tab `Snapshot` để snapshot

![](../images/kvm/snap.png)

### Cài đặt các phần mềm bổ sung 

Start lại VM login bằng user root

Cài đặt các Sofware phần mềm cần thiết (Nếu có )
- Plesk, DA, ...
- Gitlab, Owncloud


==> Sau khi cài đặt xong tiến hành shutdown và snapshot lại bản cài đặt 

### Login vào VM bằng User ROOT

### 2.2.Để máy ảo khi boot sẽ tự giãn phân vùng theo dung lượng mới, ta cài các gói sau:
```
sudo apt-get install cloud-utils cloud-initramfs-growroot -y
```

### 2.3. Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:

```sh
sudo apt-get install netplug -y
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/netplug_ubuntu -O netplug
mv netplug /etc/netplug/netplug
chmod +x /etc/netplug/netplug
```

### 2.4. Cấu hình user default

```sh
sed -i 's/name: ubuntu/name: root/g' /etc/cloud/cloud.cfg
```

### 2.5. Xóa bỏ thông tin của địa chỉ MAC
```sh
echo > /lib/udev/rules.d/75-persistent-net-generator.rules
echo > /etc/udev/rules.d/70-persistent-net.rules
```

### 2.6. Disable default config route

 - Comment dòng `link-local 169.254.0.0` trong `/etc/networks`
```sh
sed -i 's|link-local 169.254.0.0|#link-local 169.254.0.0|g' /etc/networks
```

### 2.7. Cài đặt `qemu-guest-agent`

Chú ý: qemu-guest-agent là một daemon chạy trong máy ảo, giúp quản lý và hỗ trợ máy ảo khi cần (có thể cân nhắc việc cài thành phần này lên máy ảo)

Để có thể thay đổi password máy ảo thì phiên bản qemu-guest-agent phải >= 2.5.0

```
apt-get install software-properties-common -y
add-apt-repository cloud-archive:rocky -y
apt-get update -y
apt-get install qemu-guest-agent -y
```

> Kiểm tra phiên bản `qemu-ga` bằng lệnh:
```
qemu-ga --version
service qemu-guest-agent status
```

Kết quả:
```
QEMU Guest Agent 2.11.0
* qemu-ga is running
```

### 2.8. Cấu hình datasource 

 - Bỏ chọn mục `NoCloud` bằng cách dùng dấu `SPACE`, sau đó ấn `ENTER`
```sh
dpkg-reconfigure cloud-init
```

![u18](../images/ubuntu18/u18-27.png) 

 - Clean cấu hình và restart service :
```sh
cloud-init clean
systemctl restart cloud-init
systemctl enable cloud-init
systemctl status cloud-init
```
> Thao tác `restart cloud-init` có thể tốn 2-3p để rebuild lại các config của Cloud-init

 - Clear toàn bộ history 
```sh 
apt-get clean all
rm -f /var/log/wtmp /var/log/btmp
history -c
```

 - Shutoff máy
```sh
init 0
```

## 3. Thực hiện trên Host KVM

### 3.1. Xử dụng lệnh `virt-sysprep` để xóa toàn bộ các thông tin máy ảo:
```
virt-sysprep -d canhdx-owncloud2
```

### 3.2. Dùng lệnh sau để tối ưu kích thước image:
```sh
virt-sparsify --compress --convert qcow2 /var/lib/libvirt/images/canhdx-owncloud2.qcow2 U18-OwnCloud
```

### 3.4. Upload image lên glance và sử dụng
```
glance image-create --name U18-OwnCloud --disk-format qcow2 --container-format bare --file U18-OwnCloud --visibility=public --property hw_qemu_guest_agent=yes --progress
```
