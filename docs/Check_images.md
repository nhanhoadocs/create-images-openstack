# Các bước kiểm tra Images cơ bản sau khi đóng Template

Chúng ta sẽ tạo VM từ Images này và kiểm tra 

## B1: Kiểm tra có thể tạo dung lượng min_size bao nhiêu (Dung lượng này = dung lượng file `qcow2` chúng ta tạo lúc đóng Images)

Tạo VM với dung lượng Volume = min_size (Ở đây linux là 10GB, windows trắng là 25GB,...) xem có tạo được không 

![](../images/check_images/vol1.png)

## B2: Kiểm tra khả năng tự động Extend của Volume 

Tạo VM với dung lượng lớn hơn min_size, sau khi tạo VM thì tiến hành login vào VM kiểm tra xem VM có nhận đủ dung lượng root disk không 

![](../images/check_images/vol2.png)

## B3: Kiểm tra truyền password qua cloud-init 

Truyền cloud-init khi create VM, Login thử bằng password truyền vào xem có login được không 

![](../images/check_images/cloud-init.png)

## B4: Add thêm IP xem có nhận không 

![](../images/check_images/addip.png)

## B5: Thử tính năng reset password qua nova

Để VM running và login vào Controller node sử dụng `nova set-password <VM_ID>` để set password cho VM xem có nhận password mới không 

Lấy ID của VM 
![](../images/check_images/id.png)

Set paswd mới cho VM 

![](../images/check_images/setpasswd.png)

## B6: Kiểm tra xem tab log của VM 

Trong quá trình boot VM tiến hành truy cập tab `log` xem có log MV hiển thị không 

![](../images/check_images/log.png)

## B7: Kiểm tra app của VM 

Bước này chúng ta kiểm tra hoạt động của các app trên VM sau khi running như DA, Plesk, WHM

# Edit images sau khi đóng Template

Cài đặt libguest tools
```sh 
yum install -y libguestfs || apt-get install -y libguestfs-tools
```

Chỉnh sửa Images
```sh 
root@nhcephbka02:/var/lib/libvirt/images# guestfish --rw -a  u16-qemuagent.img 

Welcome to guestfish, the guest filesystem shell for
editing virtual machine filesystems and disk images.

Type: 'help' for help on commands
      'man' to read the manual
      'quit' to quit the shell

><fs> run

 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
><fs> list-filesystems
/dev/sda1: ext4
><fs> mount /dev/sda1 /

```

# Đổi thông tin DA sau khi tạo VM từ Template

- Login vào VM 
```sh 
ssh root@<VM_IP>
```

- Check IP Public server 
```sh 
ip a
```

- Chạy script change IP 
```sh 
cd /usr/local/directadmin/scripts
./ipswap.sh 192.168.122.36 <ip-public-server>
```

- Chạy script get License
```sh 
cd /usr/local/directadmin/scripts
./getLicense.sh
service directadmin restart || systemctl restart directadmin
```

- Reboot
```sh 
init 6 
```

- Kiểm tra thông tin và đăng nhập 
```sh 
cat /usr/local/directadmin/scripts/*.txt
```

- Truy cập Dashboard DA kiểm tra 
http://<ip-public-server>:2222

# Đổi thông tin IP WHM sau khi tạo VM từ Template

CentOS
``` sh
# Update license Cpanel
/usr/local/cpanel/cpkeyclt

IP=$(ip a | grep 255 | awk '{print $2}' | cut -d '/' -f1)

# Replace IP
Example: 
replace 123.30.145.16 103.28.36.104 -- /var/cpanel/mainip 
replace 123.30.145.16 103.28.36.104 -- /etc/hosts
replace 123.30.145.16 103.28.36.104 -- /etc/wwwacct.conf
replace 123.30.145.16 103.28.36.104 -- /usr/local/apache/conf/httpd.conf

```

Thông tin đăng nhập MySQL 
```sh 
cat /root/.my.cnf
```

Truy cập 
- WHM: https://<ip-public-server>:2083
- Cpanel: https://<ip-public-server>:2087
- Mail: https://<ip-public-server>:2095

# Đổi thông tin IP Plesk sau khi tạo VM từ Template

Đổi thông tin password đăng nhập Plesk

```
https://support.plesk.com/hc/en-us/articles/115001761193-How-to-change-the-IP-address-of-Plesk-server-

https://docs.plesk.com/en-US/12.5/advanced-administration-guide-win/system-maintenance/changing-ip-addresses.49727/
```

Đăng nhập MySQL 
```sh 
plesk db
```

Truy cập 
- Plesk: https://<ip-public-server>:8443

