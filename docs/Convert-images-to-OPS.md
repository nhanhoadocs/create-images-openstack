# Các bước thực hiện 

1. Convert file `.ova`, `.vmdk`, `.vhd` sang qcow2 

2. Boot VM từ file qcow2 để xử lý images 

3. Import vào OpenStack qua Ceph

## 1. Convert file sang qcow2

- Copy file .ova vào KVM host 

- Kiểm tra file `.ova` xem disk file lưu trữ định dạng gì. 
```
[root@KVM ~]# tar -tf server.ova 
CentOS 7.ovf
ac12b598-efc7-40cc-a1ad-731ce159c420.vhd
[root@KVM ~]# 
```
> Thường thì `.vhd` với `XEN` và `.vmdk` với `VMware`

- Giải nén file .ova
```
tar -xvf server.ova
```

- Sử dụng `qemu-img` để convert file `.vhd` sang `qcow2`
```
qemu-img convert -O qcow2 ac12b598-efc7-40cc-a1ad-731ce159c420.vhd ServerKH.qcow2
```

## 2. Boot lên bằng KVM và xử lý images

Sử dụng `virt-manager` boot VM từ file qcow2 ở trên sau đó shutoff VM 

Trên KVM host: Thêm hoặc chỉnh sửa channel trong <devices> nằm trong file cấu hình  `.xml` của máy ảo mục đích để máy host giao tiếp với máy ảo sử dụng qemu-guest-agent 

`virsh edit ServerKH`

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

Start VM lên SSH vào trong VM và bắt đầu cài đặt các service cần thiết. 

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

- Kiểm tra và cài đặt module virtio trên Server 
```
find /lib/modules/ -name *virt*
dracut --add-drivers "virtio_balloon virtio_ring virtio_input virtio_pci virtio virtio_blk virtio_net caif_virtio virtio_scsi" --force
```

- Cấu hình console

Để sử dụng nova console-log, bạn cần thay đổi option cho `GRUB_CMDLINE_LINUX` và lưu lại 

``` sh
# Thay thế trong "/GRUB_CMDLINE_LINUX=" trong /etc/default/grub
`rhgb quiet` bằng `console=tty0 console=ttyS0,115200n8`
# Generating  grub configuration
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

- Kiểm tra và Xóa thông tin card mạng
``` sh
# Kiểm tra devices interface 
ip a
# Xóa cấu hình Interface tương ứng
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

## 3. Copy file đã xử lý vào OpenStack qua Ceph

### 3.1 Copy qcow2 file vào Node Ceph

Sau khi tiến hành copy file `qcow2` vào node Ceph tiến hành convert file này sang `.raw`

```
qemu-img convert -O raw ServerKH.qcow2 ServerKH.raw
```

> Lưu ý bước này không nên thực hiện bên Node KVM vì dung lượng file `.raw` khi copy sẽ tương ứng với dung lượng disk thực tế của VM (10G-20G-100G) trong khi file `.qcow2` có dung lượng thấp hơn rất nhiều.

Kiểm tra dung lượng file `.raw` ==> Dung lượng này chính là dung lượng thực tế của VM 
```
qemu-img info ServerKH.raw
```

### 3.2 Create trên OpenStack 1 Volumes

Tạo 1 Volume với kích thước tương đương dung lượng thực tế của VM 
```
openstack volume create ServerKH --size 10G
```

Enable `bootable` cho Volume trong phần chỉnh sửa Volume

![](https://i.imgur.com/WTNBXZk.png)

Lấy ID của Volume vừa tạo 
```
openstack volume list | grep ServerKH
# ==> Volume ID 05921466-3612-41a1-8826-ab710ec4cf30
```

### 3.3 Import raw file vào Ceph
Quay lại Node Ceph

```
# Kiểm tra thông tin Volume 
rbd info volumes/volume-05921466-3612-41a1-8826-ab710ec4cf30 

# Xóa volume 
rbd rm volumes/volume-05921466-3612-41a1-8826-ab710ec4cf30

# Import file raw vào Ceph với ID volume giống với ID volume cũ 
rbd import --image-format 2 ServerKH.raw volume-05921466-3612-41a1-8826-ab710ec4cf30 --pool volumes

# Kiểm tra lại Volume được import từ raw file
rbd info volumes/volume-05921466-3612-41a1-8826-ab710ec4cf30 
```

**ĐỂ ĐỒNG BỘ THÔNG TIN VOLUME GIỮA CEPH VÀ OPENSTACK TA CẦN THỰC HIỆN BƯỚC SAU**

Quay lại OpenStack `extend volume` ServerKH lên 15G 

## Hoàn tất 
Từ Volume ServerKH vừa tạo, boot 1 VM từ volume này và sử dụng [script](https://github.com/hocchudong/Image_Create/blob/master/script/partresize.sh) extend volume lvm nếu Server ban đầu sử dụng LVM 

# Tài liệu tham khảo.

http://superuser.openstack.org/articles/how-to-migrate-from-vmware-and-hyper-v-to-openstack/

http://heiterbiswolkig.blogs.nde.ag/2017/08/10/migrate-from-xen-to-kvm/

s