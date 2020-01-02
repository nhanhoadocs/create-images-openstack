# Chuẩn bị Server KVM

Kiểm tra vmx enable trên KVM host
```sh
cat /proc/cpuinfo| egrep -c "vmx|svm"
```

> Nếu OUTPUT câu lệnh trên >0 thì đã enable vmx OK 

Install epel-release và update 
```sh 
yum install epel-release -y && yum update -y 
```

Cài đặt KVM Node để đóng Images
```
yum install -y qemu-kvm qemu-img virt-manager libvirt libvirt-python libvirt-client \
virt-install virt-viewer bridge-utils  "@X Window System" xorg-x11-xauth xorg-x11-fonts-* \
xorg-x11-utils mesa-libGLU*.i686 mesa-libGLU*.x86_64 dejavu-lgc-sans-fonts
touch /root/.Xauthority
```

Start libvirt
```sh 
systemctl start --now libvirtd
```

Disable ipv6
```sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

Enable `X11Forwarding yes` trong `/etc/ssh/sshd_config`
```sh
X11Forwarding yes
```

Thêm cấu hình `/etc/ssh/sshd_config` để sử dụng X11Forward khi disable IPv6
```sh
X11Forwarding yes
AddressFamily inet
```

Restart SSH
```sh
systemctl restart sshd
```

Tạo folder channel cho các target của VM 
```
mkdir -p /var/lib/libvirt/qemu/channel/target
chown -R qemu:kvm /var/lib/libvirt/qemu/channel
```

Restart libvirt 
```sh
systemctl restart libvirtd
```

Cài libguestfs-tools để xử lý file `.qcow2` thành file `.img` sau khi cài đặt cấu hình xong VM.
```sh
yum install libguestfs-tools -y
```

Bật tính năng `nestes` cho phép ảo hóa trên VM 
```sh 
touch /etc/modprobe.d/kvm.conf
echo "options kvm_intel nested=1" > /etc/modprobe.d/kvm.conf
init 6
```

Copy Images vào VM => Tiến hành đóng Images
