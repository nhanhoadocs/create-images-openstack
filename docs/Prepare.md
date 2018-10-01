# Các Template cần đóng 

CentOS Linux (Dung lượng disk tối thiểu 10G)
- 1 - CentOS6-64bit-2018
- 2 - CentOS7-64bit-2018
- 3 - CentOS6-64bit-DA-2018
- 4 - CentOS7-64bit-DA-2018
- 5 - CentOS7-64bit-WHM-2018
- 6 - CentOS6-64bit-WHM-2018
(Có thể có Template Plesk)

Ubuntu Linux (Dung lượng disk tối thiểu 10G)
- 1 - Ubuntu14-64bit-2018
- 2 - Ubuntu14-64bit-DA-2018
- 3 - Ubuntu16-64bit-2018
- 4 - Ubuntu16-64bit-DA-2018
- 5 - Ubuntu18-64bit-2018
- 6 - Ubuntu18-64bit-DA-2018

Windows2k8 Enterprise (Dung lượng disk tối thiểu 25G)
- 1 - Windows-2008-64bit-2018
- 2 - Windows-2008-64bit-Plesk-2018

Windows2k12 Standard (Dung lượng disk tối thiểu 25G)
- 1 - Windows-2012-64bit-2018
- 2 - Windows-2012-64bit-Plesk-2018

# Chuẩn bị Server cho việc đóng images OpenStack 

Môi trường chuẩn bị:
- KVM node OS: CentOS 7 bản 1804 (Chạy trên ESXi) 
- RAM: >8G
- Disk: 200G 
- CPU: 4x2 Core

Enable `vmx` cho KVM Node trên ESXi Node
```
# Shutdown VM --> SSH to ESXi --> go to folder --> edit VM-name.vmx --> Add line
vhv.enable = "TRUE"

# Save and close the file
vim-cmd vmsvc/getallvms | grep -i <name> 
vim-cmd vmsvc/reload <id>
```

Cài đặt Vm tools
```
yum install -y open-vm-tools wget
```

Cài đặt KVM Node để đóng Images
```
grep -E '(vmx|svm)' /proc/cpuinfo
# WARNING! The remote SSH server rejected X11 forwarding request.
yum install qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client virt-install virt-viewer bridge-utils  "@X Window System"xorg-x11-xauth xorg-x11-fonts-* xorg-x11-utils -y
touch /root/.Xauthority
systemctl start libvirtd
systemctl enable libvirtd
lsmod | grep kvm
virt-manager
# Fix font 
yum install dejavu-lgc-sans-fonts -y
```

Tạo Bridge `br0` cho KVM host để đóng Images thay vì sử dụng NAT trên `virtbr0` có sẵn.
```
# Tạo mới một bridge tên là br0
nmcli c add type bridge autoconnect yes con-name br0 ifname br0
# Gán địa chỉ IP cho bridge mới tạo
nmcli c modify br0 ipv4.addresses 10.10.10.61/24 ipv4.method manual
# Đặt gateway cho bridge 
nmcli c modify br0 ipv4.gateway 10.10.10.1
# Đặt địa chỉ dns cho bridge
nmcli c modify br0 ipv4.dns 8.8.8.8
# Xóa cài đặt card mạng hiện tại
nmcli c delete ens160
# Gán card mạng hiện tại vào bridge br0
nmcli c add type bridge-slave autoconnect yes con-name ens160 ifname ens160 master br0
```

Disable ipv6
```
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

Thêm cấu hình `/etc/ssh/sshd_config` để sử dụng X11Forward khi disable IPv6
```
AddressFamily inet
```

Sử dụng `Xming Server` cài đặt trên Windows Client để thao tác với `virt-manager` qua X11 khi SSH vào Server KVM.

![](https://i.imgur.com/1uoB8Sa.png)


Tạo folder channel cho các target của VM (Chỉ thực hiện 1 lần duy nhất)
```
mkdir -p /var/lib/libvirt/qemu/channel/target
chown -R qemu:kvm /var/lib/libvirt/qemu/channel
```

Restart libvirt 
```
systemctl restart libvirtd
```

> Nếu KVM host là ubuntu, sửa file /etc/apparmor.d/abstractions/libvirt-qemu
> 
> `vi /etc/apparmor.d/abstractions/libvirt-qemu`
> 
> Thêm dòng sau vào cuối File
> 
> `/var/lib/libvirt/qemu/channel/target/*.qemu.guest_agent.0 rw,`
> 
> Mục đích là phân quyền cho phép libvirt-qemu được đọc ghi các file có hậu tố `.qemu.guest_agent.0` trong thư mục `/var/lib/libvirt/qemu/channel/target`
> 
> Khởi động lại `libvirt` và `apparmor`
> 
> ```
> service libvirt-bin restart
> service apparmor reload
> ```
>
> .

Cài libguestfs-tools để xử lý file `.qcow2` thành file `.img` sau khi cài đặt cấu hình xong VM.
```
yum install libguestfs-tools -y
```

Copy images vào folder (Có thể lấy trên Server 172.16.4.51)
```
[root@KVM ~]# ls -al /var/lib/libvirt/images/
total 18074212
drwx--x--x. 2 root root       4096 Sep 19 19:39 .
drwxr-xr-x. 9 root root       4096 Sep 19 19:00 ..
-rw-r--r--. 1 root root  427819008 Aug 31  2017 CentOS-6.9-x86_64-minimal.iso
-rw-r--r--. 1 root root  950009856 May 25 12:05 CentOS-7-x86_64-Minimal-1804.iso
-rw-r--r--. 1 root root 2996799488 Sep 18 09:09 SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008R2_64-bit_English_X15-59754.ISO
-rw-r--r--. 1 root root 5400115200 Sep 18 09:04 SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_-4_MLF_X19-82891.ISO
-rw-r--r--. 1 root root 6003804160 Sep 18 09:37 SW_DVD9_Win_Server_STD_CORE_2016_64Bit_English_-4_DC_STD_MLF_X21-70526.ISO
-rw-r--r--. 1 root root  649068544 Sep  9 09:48 ubuntu-14.04.5-server-amd64.iso
-rw-r--r--. 1 root root  912261120 Sep  9 09:51 ubuntu-16.04.5-server-amd64.iso
-rw-r--r--. 1 root root  851443712 Sep  9 10:09 ubuntu-18.04.1-live-server-amd64.iso
-rw-r--r--. 1 root root  316628992 Aug  5  2017 virtio-win-0.1.141.iso
[root@KVM ~]# 
```

Hoàn tất cài đặt KVM host để đóng Images, Tiến hành đóng Images
