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

 - Tạo máy ảo với tool *Virt-Manager*. Import file disk máy ảo. 
 
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


### 1.2. Chỉnh sửa file .xml của máy ảo, bổ sung thêm channel trong `<devices>` (để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent), sau đó save lại
`virsh edit u18-01`

với `u18-01` là tên máy ảo
```
...
<devices>
 <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
 </channel>
</devices>
```

### 1.3. Tạo thêm thư mục cho channel vừa tạo và phân quyền cho thư mục đó
```
mkdir -p /var/lib/libvirt/qemu/channel/target
chown -R libvirt-qemu:kvm /var/lib/libvirt/qemu/channel
```

### 1.4. Dùng `vim` để sửa file `/etc/apparmor.d/abstractions/libvirt-qemu`
`vim /etc/apparmor.d/abstractions/libvirt-qemu`

Bổ sung thêm cấu hình sau vào dòng cuối cùng
```
 /var/lib/libvirt/qemu/channel/target/*.qemu.guest_agent.0 rw,
```
#### *Mục đích là phân quyền cho phép libvirt-qemu được đọc ghi các file có hậu tố `.qemu.guest_agent.0` trong thư mục `/var/lib/libvirt/qemu/channel/target`*

Khởi động lại `libvirt` và `apparmor`
```
service libvirt-bin restart
service apparmor reload
```

### 1.5. Bật máy ảo

## 2. Thực hiện trên máy ảo

### 2.1. Setup môi trường 

 - Cấu hình cho phép login root và xóa user ubuntu chỉnh vi /etc/ssh/sshd_config
```sh
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'g /etc/ssh/sshd_config
service sshd restart
```

 - Chỉnh sửa timezone về Asia/Ho_Chi_Minh
```sh
dpkg-reconfigure tzdata
```

 - Disable ipv6
```
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf 
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
# Kiểm tra config add thành công 
sysctl -p
# Kiểm tra disable ipv6 
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
# Output: 1: OK, 0: NotOK
```

 - Update
```sh
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
```

### 2.2.Để máy ảo khi boot sẽ tự giãn phân vùng theo dung lượng mới, ta cài các gói sau:
```
apt-get install cloud-utils cloud-initramfs-growroot -y
```

### 2.3. Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:

```sh
apt-get install netplug -y
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/netplug_ubuntu -O netplug
mv netplug /etc/netplug/netplug
chmod +x /etc/netplug/netplug
```

### 2.3. Cấu hình user default

```sh
sed -i 's/name: ubuntu/name: root/g' /etc/cloud/cloud.cfg
```

### 2.4. Xóa bỏ thông tin của địa chỉ MAC
```sh
echo > /lib/udev/rules.d/75-persistent-net-generator.rules
echo > /etc/udev/rules.d/70-persistent-net.rules
```

### 2.5. Cấu hình để instance báo log ra console và đổi name Card mạng về eth* thay vì ens, eno
```sh
sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 console=tty1 console=ttyS0"|g' /etc/default/grub
update-grub
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

#### Kiểm tra phiên bản `qemu-ga` bằng lệnh:
```
qemu-ga --version
service qemu-guest-agent status
```

Kết quả:
```
QEMU Guest Agent 2.11.0
* qemu-ga is running
```

### 2.8. Cấu hình network sử dụng ifupdown thay vì netplan

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

### 2.9. Cấu hình datasource 

 - Bỏ chọn mục `NoCloud` bằng cách dùng dấu `SPACE`, sau đó ấn `ENTER`
```sh
dpkg-reconfigure cloud-init
```

![u18](/ghichep/ManhDV/images/u18-27.png) 

 - Clean cấu hình và restart service :
```sh
cloud-init clean
systemctl restart cloud-init
```


 - Shutdown máy
```sh
init 0
```

### 2.10 Kiểm tra
 - Restart máy ảo và kiểm tra service cloud-init

```
systemctl status cloud-init
```

 - Start service cloud-init và tắt máy
```sh
systemctl start cloud-init
init 0
```

## 3. Thực hiện trên Host KVM
### 3.1. Cài đặt bộ libguestfs-tools để xử lý image (nên cài đặt trên Ubuntu OS để có bản libguestfs mới nhất)
```
apt-get install libguestfs-tools -y
```

### 3.2. Xử dụng lệnh `virt-sysprep` để xóa toàn bộ các thông tin máy ảo:
```
virt-sysprep -d u18.qcow2
```

### 3.3. Dùng lệnh sau để tối ưu kích thước image:
```sh
virt-sparsify --compress --convert qcow2 /var/lib/libvirt/images/u18-02.qcow2 /var/lib/libvirt/images/u18-02.img```
```

### 3.4. Upload image lên glance và sử dụng
```
glance image-create --name ubuntu18.04_v1 --disk-format qcow2 --container-format bare --file /root/images/u18-02.img --visibility=public --property hw_qemu_guest_agent=yes --progress
```
