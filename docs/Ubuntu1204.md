# Hướng dẫn đóng image Ubuntu 12.04 với cloud-init (không dùng LVM)

## Chú ý:

- Để cài được Cloud init thì chủ sử dụng được .iso Ubuntu12.04.4 (KHÔNG SỬ DỤNG Ubuntu12.04.5 )
- Hướng dẫn này dành cho các image không sử dụng LVM
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- OS node KVM là Centos7
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

----------------------

## Bước 1: Tạo máy ảo bằng virt-manager

![](../images/ubuntu12/u12_install_00.png)

![](../images/ubuntu12/u12_install_01.png)

![](../images/ubuntu12/u12_install_02.png)

![](../images/ubuntu12/u12_install_03.png)

![](../images/ubuntu12/u12_install_04.png)

![](../images/ubuntu12/u12_install_05.png)

![](../images/ubuntu12/u12_install_06.png)

![](../images/ubuntu12/u12_install_07.png)

![](../images/ubuntu12/u12_install_08.png)

![](../images/ubuntu12/u12_install_09.png)

![](../images/ubuntu12/u12_install_10.png)

![](../images/ubuntu12/u12_install_11.png)

![](../images/ubuntu12/u12_install_12.png)

![](../images/ubuntu12/u12_install_13.png)

![](../images/ubuntu12/u12_install_14.png)

![](../images/ubuntu12/u12_install_15.png)

![](../images/ubuntu12/u12_install_16.png)

![](../images/ubuntu12/u12_install_17.png)

![](../images/ubuntu12/u12_install_18.png)

![](../images/ubuntu12/u12_install_19.png)

![](../images/ubuntu12/u12_install_20.png)

![](../images/ubuntu12/u12_install_21.png)

![](../images/ubuntu12/u12_install_22.png)

![](../images/ubuntu12/u12_install_23.png)

![](../images/ubuntu12/u12_install_24.png)

![](../images/ubuntu12/u12_install_25.png)

![](../images/ubuntu12/u12_install_26.png)

![](../images/ubuntu12/u12_install_27.png)

![](../images/ubuntu12/u12_install_28.png)

![](../images/ubuntu12/u12_install_29.png)

![](../images/ubuntu12/u12_install_30.png)

![](../images/ubuntu12/u12_install_31.png)

![](../images/ubuntu12/u12_install_32.png)

![](../images/ubuntu12/u12_install_33.png)

![](../images/ubuntu12/u12_install_34.png)

![](../images/ubuntu12/u12_install_35.png)

![](../images/ubuntu12/u12_install_36.png)

![](../images/ubuntu12/u12_install_37.png)

![](../images/ubuntu12/u12_install_38.png)

![](../images/ubuntu12/u12_install_39.png)

![](../images/ubuntu12/u12_install_40.png)

![](../images/ubuntu12/u12_install_41.png)

![](../images/ubuntu12/u12_install_42.png)

![](../images/ubuntu12/u12_install_43.png)

![](../images/ubuntu12/u12_install_44.png)

![](../images/ubuntu12/u12_install_45.png)

![](../images/ubuntu12/u12_install_46.png)

![](../images/ubuntu12/u12_install_47.png)

![](../images/ubuntu12/u12_install_48.png)

![](../images/ubuntu12/u12_install_49.png)

![](../images/ubuntu12/u12_install_50.png)

![](../images/ubuntu12/u12_install_51.png)

![](../images/ubuntu12/u12_install_52.png)

![](../images/ubuntu12/u12_install_53.png)

## Bước 2 : Tắt máy ảo, xử lí trên KVM host

- Chỉnh sửa file `.xml` của máy ảo, bổ sung thêm channel trong <devices> (để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent), sau đó save lại

`virsh edit ubuntu12`

với `ubuntu12` là tên máy ảo

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


## Bước 3: Cài các dịch vụ cần thiết

Bật máy ảo lên, truy cập vào máy ảo. Lưu ý với lần đầu boot, bạn phải sử dụng tài khoản tạo trong quá trình cài os, chuyển đổi nó sang tài khoản root để sử dụng.

Cấu hình cho phép login root và xóa user `ubuntu` chỉnh `vi /etc/ssh/sshd_config`
```sh
PermitRootLogin yes
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
service ssh restart
```

Disable firewalld 
```sh
sudo ufw disable
```

Logout và login lại bằng user `root` và xóa user `ubuntu`
```sh
userdel ubuntu
rm -rf /home/ubuntu
```

Update 
```sh
sudo apt-get update -y 
sudo apt-get upgrade -y 
sudo apt-get dist-upgrade -y
sudo apt-get autoremove 
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
# Kiểm tra config add thành công 
sysctl -p
# Kiểm tra disable ipv6 
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
# Output: 1: OK, 0: NotOK
```

==> SNAPSHOT lại KVM host để lưu trữ và đóng gói lại khi cần thiết

- Shutdown VM 

![](../images/kvm/shutdown.png)

- Tiến hành truy cập tab `Snapshot` để snapshot

![](../images/kvm/snap.png)

**Cài đặt cloud-init, cloud-utils và cloud-initramfs-growroot**

```sh
apt-get install cloud-utils cloud-initramfs-growroot cloud-init -y
```

## Bước 4: Cấu hình để instance nhận metadata từ datasource

```sh
dpkg-reconfigure cloud-init
```

Sau khi màn hình mở ra, lựa chọn mối `EC2`

## Bước 5: Cấu hình user nhận ssh keys

Thay đổi file `/etc/cloud/cloud.cfg` để chỉ định user nhận ssh keys khi truyền vào, mặc định là `root`

``` sh
sed -i 's|user: ubuntu|user: root|g' /etc/cloud/cloud.cfg
sed -i 's|disable_root: 1|disable_root: 0|g' /etc/cloud/cloud.cfg
```

## Bước 6: Xóa bỏ thông tin của địa chỉ MAC

Xóa nội dung file (file này được gen bởi file trước) bằng các sử dụng `:%d`  trong `vi`.
```sh 
echo > /lib/udev/rules.d/75-persistent-net-generator.rules
echo > /etc/udev/rules.d/70-persistent-net.rules
```

Bạn cũng có thể thay thế file trên bằng 1 file rỗng. Lưu ý: không được xóa bỏ hoàn toàn file mà chỉ xóa nội dung.

## Bước 7: Cấu hình để instance báo log ra console

```sh
sed -i 's|GRUB_HIDDEN_TIMEOUT_QUIET=true|#GRUB_HIDDEN_TIMEOUT_QUIET=true|g' /etc/default/grub
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=""|GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0"|g' /etc/default/grub
sed -i 's|GRUB_TERMINAL=console|GRUB_TERMINAL=console|g' /etc/default/grub
```

Lưu lại config 
```sh 
update-grub
```

## Bước 8: Cài đặt netplug

- Cài đặt netplug để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:

``` sh
apt-get install netplug -y
wget https://raw.githubusercontent.com/uncelvel/create-images-openstack/master/scripts_all/netplug_ubuntu -O netplug
mv netplug /etc/netplug/netplug
chmod +x /etc/netplug/netplug
```

## Bước 9: Disable default config route

```sh
sed -i 's|link-local 169.254.0.0|#link-local 169.254.0.0|g' /etc/networks
```

## Bước 10: Cài đặt qemu-guest-agent

Ubuntu 12 không hỗ trợ `qemu-guest-agent` sẽ không hỗ trợ tính năng đổi password bằng `nova set-password`

Chúng ta sẽ phải set password qua SingleMode trên Console

## Bước 11: Cấu hình card mạng tự động active khi hệ thống boot-up

``` sh
vim /etc/network/interfaces

auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
```

## Bước 12: Tắt máy ảo

```sh
init 0
```

## Bước 13: Clean up image

```
virt-sysprep -d ubuntu12
```

## Bước 14: Giảm kích thước máy ảo

```sh
virt-sparsify --compress /var/lib/libvirt/images/ubuntu12.qcow2 /root/ubuntu12.img
```

**Lưu ý:**

Nếu img bạn sử dụng đang ở định dạng raw thì bạn cần thêm tùy chọn `--convert qcow2` để giảm kích thước image.

## Bước 15: Upload image lên glance

- Copy image tới máy CTL, sử dụng câu lệnh sau

``` sh
glance image-create --name ubuntu12-64bit-2018 \
--disk-format qcow2 \
--container-format bare \
--file ubuntu12-64bit-2018.img \
--visibility=public \
--property hw_qemu_guest_agent=yes \
--progress
```

- Images đã sẵn sàng để Create máy ảo.

**Link tham khảo:**

https://github.com/hocchudong/Image_Create/blob/master/docs/ubuntu12.04_noLVM%2Bqemu_ga.md

https://www.victordodon.com/fix-problem-running-iptables-on-a-digitalocean-droplet/
