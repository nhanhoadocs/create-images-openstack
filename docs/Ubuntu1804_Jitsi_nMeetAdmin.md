# Tài liệu hướng dẫn đóng image Jitsi tích hợp trang quản trị Meetnow Admin trên Ubuntu 18.04

## Chú ý:
- Hướng dẫn này dành cho các image không sử dụng LVM
- Sử dụng công cụ virt-manager hoặc web-virt để kết nối tới console máy ảo
- OS : Ubuntu 18.04 LTS
- Phiên bản OpenStack sử dụng là Queens
- Hướng dẫn bao gồm 2 phần chính: thực hiện trên máy ảo cài OS và thực hiện trên KVM Host

## Thực hiện:
- Đóng image trên KVM
- Cấu hình ban đầu: 
    - RAM: 2 GB
    - Disk: 10 GB
    - CPU: 2

## Thông số cài đặt:
- OS: Ubuntu 18.04 LTS

- Thông số phiên bản các service của Jitsi:
    - jicofo=1.0-541-1 
    - jitsi-meet=2.0.4384-1
    - jitsi-meet-prosody=1.0.3969-1 
    - jitsi-meet-turnserver=1.0.3969-1 
    - jitsi-meet-web=1.0.3969-1 
    - jitsi-meet-web-config=1.0.3969-1 
    - jitsi-videobridge2=2.1-164-gfdce823f-1

# Cài đặt Ubuntu 18.04 LTS
- Tiến hành cài đặt Ubuntu 18.04 LTS như bình thường
- Sau khi cài đặt xong, ta tiến hành sang bước đóng image

# I. Thực hiện trên VM
## 1. Thiết lập cơ bản
### Setup cơ bản Ubuntu:
- Bật máy ảo, truy cập bằng tài user ubuntu và bắt đầu thực hiện cài đặt môi trường.
    ```
    sudo su

    # Đặt mật khẩu cho root
    passwd
    Enter new UNIX password: <root_passwd>
    Retype new UNIX password: <root_passwd>
    ```


- Cấu hình cho phép ssh bằng user root `/etc/ssh/sshd_config`
    ```
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'g /etc/ssh/sshd_config

    sed -i 's/#PasswordAuthentication yes/#PasswordAuthentication yes/'g /etc/ssh/sshd_config

    service sshd restart
    ```

- Disable firewalld
    ```
    systemctl disable ufw
    systemctl stop ufw
    systemctl status ufw
    ```

- Logout ra khỏi VM:
    ```
    logout
    ```

- Login lại bằng user `root`

- Xóa user `ubuntu`
    ```
    userdel ubuntu
    rm -rf /home/ubuntu
    ```

- Đổi timezone về `Asia/Ho_Chi_Minh`
    ```
    timedatectl set-timezone Asia/Ho_Chi_Minh
    ```

- Bổ sung env locale
    ```
    echo "export LC_ALL=C" >>  ~/.bashrc
    ```

- Disable ipv6
    ```
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf 
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf 
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p

    cat /proc/sys/net/ipv6/conf/all/disable_ipv6
    ```
    **OUTPUT**: `1: OK, 0: Not OK`

- Kiểm tra và xóa swap:
    - Kiểm tra swap:
        ```
        cat /proc/swaps
        Filename                                Type            Size    Used    Priority
        /swap.img                               file            4038652 0       -2
        ```

    - Xóa swap:
        ```
        swapoff -a
        rm -rf /swap.img
        ```

    - Xóa cấu hình swap file trong file /etc/fstab
        ```
        sed -Ei '/swap.img/d' /etc/fstab
        ```

    - Kiểm tra lại:
        ```
        free -m
        ```

## 2. Cài đặt các gói cần thiết
- Update
    ```
    apt-get update -y 
    apt-get upgrade -y 
    apt-get dist-upgrade -y
    apt-get autoremove -y
    ```

- Cấu hình để instance báo log ra console và đổi name Card mạng về eth* thay vì ens, eno
    ```
    sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 console=tty1 console=ttyS0"|g' /etc/default/grub

    update-grub
    ```

### 2.1. Cấu hình network sử dụng ifupdown thay vì netplan
- Disable netplan
    ```
    apt-get --purge remove netplan.io -y
    rm -rf /usr/share/netplan
    rm -rf /etc/netplan

    apt-get update
    apt-get install -y ifupdown
    ```

- Tạo file interface
    ```
    cat << EOF > /etc/network/interfaces
    auto lo
    iface lo inet loopback
    auto eth0
    iface eth0 inet dhcp
    EOF
    ```

- Reboot máy, kiểm tra card eth0

### 2.2. Để sau khi boot máy ảo, có thể nhận đủ các NIC gắn vào:
```
apt-get install netplug -y

wget https://raw.githubusercontent.com/danghai1996/thuctapsinh/master/HaiDD/CreateImage/scripts/netplug_ubuntu -O netplug

mv netplug /etc/netplug/netplug

chmod +x /etc/netplug/netplug
```

### 2.3. Disable snapd service:
Kiểm tra snap:
```
df -H

Filesystem      Size  Used Avail Use% Mounted on
udev            2.1G     0  2.1G   0% /dev
tmpfs           414M  6.1M  408M   2% /run
/dev/vda2        22G  2.2G   18G  11% /
tmpfs           2.1G     0  2.1G   0% /dev/shm
tmpfs           5.3M     0  5.3M   0% /run/lock
tmpfs           2.1G     0  2.1G   0% /sys/fs/cgroup
/dev/loop0       93M   93M     0 100% /snap/core/7270
tmpfs           414M     0  414M   0% /run/user/0
```

List danh sách snap
```
snap list

Name  Version    Rev   Tracking       Publisher   Notes
core  16-2.39.3  7270  latest/stable  canonical*  core
```

Remove snapd package
```
apt purge snapd -y
```
Kiểm tra lại
```
df -H
Filesystem      Size  Used Avail Use% Mounted on
udev            2.1G     0  2.1G   0% /dev
tmpfs           414M  6.1M  408M   2% /run
/dev/vda2        22G  2.1G   18G  11% /
tmpfs           2.1G     0  2.1G   0% /dev/shm
tmpfs           5.3M     0  5.3M   0% /run/lock
tmpfs           2.1G     0  2.1G   0% /sys/fs/cgroup
tmpfs           414M     0  414M   0% /run/user/0
```

> ## Snapshot VM -> OS_Ubuntu1804

## 3. Cài đặt Jitsi
### 3.1. Đặt hostname
```
hostnamectl set-hostname jitsimeet
bash
```

### 3.2. Cài đặt OpenJDK Java Runtime Environment (JRE) 8
Enable repo universe nếu chưa được kích hoạt
```
sudo add-apt-repository universe
```

Cài đặt OpenJDK JRE 8:
```
sudo apt install -y openjdk-8-jre-headless
```

Kiểm tra:
```
java -version
```

Cấu hình môi trường JAVA_HOME
```
echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | sudo tee -a /etc/profile
source /etc/profile
```

### 3.3. Cài đặt Nginx
```
sudo apt install -y nginx
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
```

### 3.4. Cài đặt Jitsi Meet
Cài Jitsi repo:
```
cd
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -

sudo sh -c "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list"

sudo apt update -y
```

Cài đặt Jitsi theo phiên bản đã định sẵn ở trên:
```
apt-get install jicofo=1.0-541-1 jitsi-meet=2.0.4384-1 jitsi-meet-prosody=1.0.3969-1 jitsi-meet-turnserver=1.0.3969-1 jitsi-meet-web=1.0.3969-1 jitsi-meet-web-config=1.0.3969-1 jitsi-videobridge2=2.1-164-gfdce823f-1 -y
```

Trong quá trình cài đặt, sẽ được yêu cầu điền hostname. Tại đó, điền IP máy chủ

Sau đó, ta sẽ được hỏi về SSL cert: -> Chọn `Generate a new self-signed certificate (You will later get a chance to obtain a Let’s Encrypt certificate)`


Restart các service:
```
systemctl start prosody
systemctl enable prosody

systemctl start jicofo
systemctl enable jicofo

systemctl start jitsi-videobridge2.service
systemctl enable jitsi-videobridge2

systemctl restart nginx
```

Truy cập bằng IP của máy ảo

<img src="..\images\ubuntu18_jitsi_nMeetAdmin\Screenshot_1.png">

## 4. Cài đặt MeetnowAdmin cho Jitsi
Cài đặt theo tài liệu:

https://github.com/cloud365vn/NH-Jitsi/blob/development/docs/jitsi-ubuntu-deploy.md

Tắt chế độ Debug
```
sed -i 's|DEBUG = True|DEBUG = False|g' /opt/NH-Jitsi/project/settings/base.py
```

## 5. Cài đặt các tính năng thêm cho Jitsi
### 5.1. Tắt tự động đặt tên phòng
Vào file `/usr/share/jitsi-meet/interface_config.js`, tìm đến dòng `GENERATE_ROOMNAMES_ON_WELCOME_PAGE` sửa giá trị true thành `false`.
```
sed -i 's|GENERATE_ROOMNAMES_ON_WELCOME_PAGE: true,|GENERATE_ROOMNAMES_ON_WELCOME_PAGE: false,|g' /usr/share/jitsi-meet/interface_config.js
```

### 5.2. Cấu hình để người dùng mobile :truy cập được vào bằng trình duyệt
Vào file `/etc/jitsi/meet/<domain>-config.js`. Ở đây là IP: `/etc/jitsi/meet/10.10.30.188-config.js`, thêm dòng 
```
disableDeepLinking: true,
```

### 5.3. Tắt camera của người vào phòng khi họ mới vào
Vào file `/etc/jitsi/meet/<domain>-config.js`. Ở đây là IP: `/etc/jitsi/meet/10.10.30.188-config.js`, thêm dòng 
```
startWithVideoMuted: true,
```

### 5.4. Tắt làm mờ background video
Vào file `/usr/share/jitsi-meet/interface_config.js`, sửa dòng: `DISABLE_VIDEO_BACKGROUND`
```
sed -i 's|DISABLE_VIDEO_BACKGROUND: false,|DISABLE_VIDEO_BACKGROUND: true,|g' /usr/share/jitsi-meet/interface_config.js
```

Sau đó, xóa `videobackgroundblur` tại mục `TOOLBAR_BUTTONS` để bỏ chức năng làm mờ background đi
```
sed -i "s|'videobackgroundblur',||g" /usr/share/jitsi-meet/interface_config.js
```

### 5.5. Tắt hoạt ảnh feedback
Sửa các dòng ở file `/usr/share/jitsi-meet/interface_config.js`
```
sed -i 's|DISABLE_FOCUS_INDICATOR: false,|DISABLE_FOCUS_INDICATOR: true,|g' /usr/share/jitsi-meet/interface_config.js

sed -i 's|DISABLE_DOMINANT_SPEAKER_INDICATOR: false,|DISABLE_DOMINANT_SPEAKER_INDICATOR: true,|g' /usr/share/jitsi-meet/interface_config.js
```

### 5.6. Update file tiếng Việt
Tải file tiếng việt đã được chỉnh sửa lại tại: https://github.com/cloud365vn/NH-Jitsi/blob/master/lang/main-vi.json

Thay thế nội dung file `/usr/share/jitsi-meet/lang/main-vi.json` bằng file tải về
```
cat file_main-vi.json-custom  > /usr/share/jitsi-meet/lang/main-vi.json

# Xóa file custom
rm -f file_main-vi.json-custom
```

### 5.7. Cấu hình crontab để xóa các user ảo tồn đọng trên hệ thống
Tạo một script
```
cat << EOF >> /bin/restartJitsiService.sh
#!/bin/bash
DATE=\$(date "+%T %d/%m/%Y")
 
/etc/init.d/jicofo restart
/etc/init.d/prosody restart
/etc/init.d/jitsi-videobridge2 restart
 
echo "Da thuc hien Script restart vao luc $DATE" >> /var/log/jitsi/scriptRestart.log
EOF
```
Sau đó phân quyền cho script:
```
chmod +x /bin/restartJitsiService.sh
```
Kiểm tra:

```
ll /bin/ | grep restartJitsiService.sh
```

Cấu hình crontab để chạy script vào 12h trưa và 12h đêm hằng ngày. Mở crontab:
```
crontab -e
```

Thêm vào dòng sau:
```
00 00,12 * * * /bin/restartJitsiService.sh
```

> ## Snap shot > Jitsi-admin

## 6. Cài đặt qemu-agent
Chú ý: `qemu-guest-agent` là một daemon chạy trong máy ảo, giúp quản lý và hỗ trợ máy ảo khi cần (có thể cân nhắc việc cài thành phần này lên máy ảo)

Để có thể thay đổi password máy ảo bằng nova-set password thì phiên bản `qemu-guest-agent` phải `>= 2.5.0`
```
apt-get install software-properties-common -y
apt-get update -y
apt-get install qemu-guest-agent -y
service qemu-guest-agent start
```

Kiểm tra phiên bản qemu-ga bằng lệnh:
```
qemu-ga --version
service qemu-guest-agent status
```

## 7. Cài đặt CMD Log
```
curl -Lso- https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/cmdlog.sh | bash
```

## 8. Để máy ảo khi boot sẽ tự giãn phân vùng theo dung lượng mới, ta cài các gói sau:
```
sudo apt-get install cloud-utils cloud-initramfs-growroot -y
```

## 9. Cài đặt gói Cloud-init
Cài đặt cloud-init
```
apt-get install -y cloud-init
```

Cấu hình user mặc định
```
sed -i 's/name: ubuntu/name: root/g' /etc/cloud/cloud.cfg
```

Disable default config route
```
sed -i 's|link-local 169.254.0.0|#link-local 169.254.0.0|g' /etc/networks
```

Cấu hình datasource, bỏ chọn mục NoCloud bằng cách dùng dấu SPACE, sau đó ấn ENTER
```
dpkg-reconfigure cloud-init
```

<img src="..\images\ubuntu18_jitsi_nMeetAdmin\Screenshot_2.png">

Clean cấu hình và restart service
```
cloud-init clean
systemctl restart cloud-init
systemctl enable cloud-init
systemctl status cloud-init
```

## 10. Xóa các user của trang quản trị admin
```
echo "from users.models import User; User.objects.all().delete()" | /opt/env/bin/python /opt/NH-Jitsi/manage.py shell
```

## 11. Dọn dẹp
Đổi tất cả IP về một biến: `ip.address.vm`
```
bash /opt/NH-Jitsi/scripts/jitsi_change_domain.sh ip.address.vm

sed -Ei "s|10.10.30.188|ip.address.vm|g" /etc/nginx/sites-available/nmeet-admin

source /opt/env/bin/activate
/opt/env/bin/python /opt/NH-Jitsi/manage.py update_domain --settings=project.settings.thanhnb02
```

Clear toàn bộ history, các file log
```
source .bashrc
apt-get clean all
rm -f /var/log/wtmp /var/log/btmp

> /var/log/prosody/prosody.log
> /var/log/prosody/prosody.err
> /var/log/jitsi/jicofo.log
> /var/log/jitsi/jvb.log
> /var/log/jitsi/scriptRestart.log

history -c
> /root/.bash_history
> /var/log/cmdlog.log
```

Tắt VM

> ## Snapshot VM  -> Jitsi-nMeetAdmin-Final

# II. Thực hiện trên Host KVM
### Bước 1: Xử dụng lệnh `virt-sysprep` để xóa toàn bộ các thông tin máy ảo
```
virt-sysprep -d haidd-jitsi-admin
```

### Bước 2: Tối ưu kích thước image:
```
virt-sparsify --compress --convert qcow2 /kvm/haidd-jitsi-admin.qcow2 U18-Jitsi-Admin
```

### Bước 3: Upload image với metatdata
```
hw_qemu_guest_agent=yes
```

### Bước 4: Cloud-init
```conf
#cloud-config
password: '{vps_password}'
chpasswd: { expire: False }
ssh_pwauth: True
runcmd:
    - curl https://raw.githubusercontent.com/danghai1996/thuctapsinh/master/HaiDD/CreateImage/scripts/jitsi_admin.sh -o /tmp/jitsi_admin.sh
    - chmod +x /tmp/jitsi_admin.sh
    - bash /tmp/jitsi_admin.sh {vps_da_password}
    - rm -f /tmp/jitsi_admin.sh
```