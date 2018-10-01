# Cài đặt cấu hình cho VM CentOS7 chuyển dịch lên Cloud365 OpenStack của Nhân Hòa

## Giai đoạn 1: Khách hàng tự thao tác trên hệ thống của Khách hàng.

> Khuyến cáo: Copy file disk `.ova`, `.vmdk`, `.vhd` (Hoặc Snapshot VM)... nhằm mục đích backup VM trước khi thao tác. 

Các bước sau thao tác trên VM 

### B1: Cài đặt acpid (Bắt buộc có)

Mục đích: Cung cấp các tập lệnh có sẵn cho phép hypervisor OpenStack có thể reboot hoặc shutdown instance.

``` sh 
yum install acpid -y
systemctl enable acpid
```

### B2: Cài đặt qemu guest agent (Bắt buộc có)

Mục đích: Là 1 agent chạy phí trong VM cho phép hypervisor OpenStack có thể tương tác với VM thực hiện các lệnh của ACPI như `reboot`, `shutdown` ...

``` sh 
systemctl enable qemu-guest-agent.service
systemctl start qemu-guest-agent.service
```

### B3: Cài đặt cloud-init và cloud-utils (Tùy chọn)

Mục đích: Cloud-init cung cấp tiện ích đặt password, reset password khi chuyển dịch lên hệ thống Cloud365 OpenStack của Nhân Hòa

``` sh
yum install qemu-guest-agent cloud-init cloud-utils -y
```

Để máy ảo trên OpenStack có thể nhận được Cloud-init cần thay đổi cấu hình mặc định bằng cách sửa đổi file `/etc/cloud/cloud.cfg`. 

``` sh
sed -i 's/disable_root: 1/disable_root: 0/g' /etc/cloud/cloud.cfg
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   1/g' /etc/cloud/cloud.cfg
sed -i 's/name: centos/name: root/g' /etc/cloud/cloud.cfg
```

Để VM có thể nhận được Metadata từ Cloud-init cần Disable Default routing trong quá trình khởi động để VM có thể nhận được metadata từ `169.254.0.0/16` 

``` sh
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
```

==> Nếu khách hàng ko muốn sử dụng tính năng này có thể bỏ qua. Khách hàng sẽ không thể sử dụng các tính năng như 

- Chèn password khi tạo VM
- Reset password trên OpenStack khi quên password
- ...

### B4: Cài đặt module virtio (Bắt buộc có)

Mục đích: `Virtio. Paravirtualized drivers for kvm/Linux`

``` sh 
# Kiểm tra và cài đặt module virtio trên Server 
find /lib/modules/ -name *virt*
# Cài đặt driver 
dracut --add-drivers "virtio_balloon virtio_ring virtio_input virtio_pci virtio virtio_blk virtio_net caif_virtio virtio_scsi" --force
```

### B5: Cấu hình grub (Bắt buộc có)

Mục đích: Cấu hình console để sử dụng nova console-log

Trong file `/etc/default/grub` thay đổi nội dung phần `GRUB_CMDLINE_LINUX=` thay thế `rhgb quiet` bằng `console=tty0 console=ttyS0,115200n8`

``` sh
# Generating lại file cấu hình grub để nhận tham số mới.
grub2-mkconfig -o /boot/grub2/grub.cfg
```

### B5: Làm sạch máy để chuyển lên Cloud365 OpenStack của Nhân Hòa (Bắt buộc có)

Kiểm tra và Xóa thông tin card mạng, hostname (Mục đích: VM khởi chạy sẽ tự động sinh ra thông tin card mạng hostname tương ứng phù hợp với Hypervisor OpenStack của Cloud365 Nhân Hòa)

``` sh
# Kiểm tra devices interface 
ip a
# Xóa cấu hình Interface tương ứng ở đây VD là eth0
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0
# Xóa file hostname
rm -f /etc/hostname
```

Tắt VM 

```
poweroff
```

Copy file disk (`.ova`, `.vmdk`, `.vhd` ...) sau khi xử lý chuyển giao cho Nhân Hòa.

## Giai đoạn 2: Nhân Hòa tiếp nhận file VM và import lên hệ thống Cloud 365

- Chuyển đổi định dạng phù hợp và import file disk vào Storage.
- Khởi tạo VM từ file disk trên Storage theo dung lượng yêu cầu.
- Gửi lại Khách hàng IP, khách hàng sẽ đăng nhập với thông tin và tài khoản ban đầu của khách hàng, (phía Nhân Hòa ko tác động gì đến VM và phía trong VM của khách hàng)

## Giai đoạn 3: Hoàn tất

Phía Khách hàng chủ động login vào VM và kiểm tra các thông tin về Data lưu trữ, hoạt động của VM.... 

Phía Nhân Hòa có trách nhiệm hỗ trợ nếu có phát sinh trong quá trình chuyển đổi. 

Quá trình này được lặp lại cho đến khi Khách Hàng confirm với Nhân Hòa rằng VM hoạt động ổn định trên nền tảng Cloud365 mà Nhân Hòa cung cấp.

Hoàn tất quá trình chuyển đổi.