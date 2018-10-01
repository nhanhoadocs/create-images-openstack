serial --unit=1 --speed=19200 --word=8 --parity=no --stop=1
console=tty0 console=ttyS1,19200n8

# Hướng dẫn thay đổi password

## Cách 1: sử dụng nova API (lưu ý máy ảo phải đang bật)

Trên node Controller, thực hiện lệnh và nhập password cần đổi

``` sh
root@controller:# nova set-password CentOS7
New password:
Again:
```

với `CentOS7` là tên máy ảo

## Cách 2: sử dụng trực tiếp libvirt

Xác định vị trí máy ảo đang nằm trên node compute nào. VD máy ảo đang sử dụng là CentOS7

`root@controller:# nova show CentOS7`

Kết quả:

``` sh
+--------------------------------------+----------------------------------------------------------------------------------------------------------+
| Property                             | Value                                                                                                    |
+--------------------------------------+----------------------------------------------------------------------------------------------------------+
| OS-DCF:diskConfig                    | AUTO                                                                                                     |
| OS-EXT-AZ:availability_zone          | nova                                                                                                     |
| OS-EXT-SRV-ATTR:host                 | compute2                                                                                                 |
| OS-EXT-SRV-ATTR:hostname             | CentOS7                                                                                                   |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | compute2                                                                                                 |
| OS-EXT-SRV-ATTR:instance_name        | instance-00000003                                                                                        |
```

Như vậy máy ảo nằm trên node compute2 với KVM name là `instance-00000003`

Kiểm tra trên máy compute2 để tìm file socket kết nối tới máy ảo

`bash -c  "ls /var/lib/libvirt/qemu/*.sock"`

Kết quả:

`/var/lib/libvirt/qemu/org.qemu.guest_agent.0.instance-00000003.sock`

instance-00000003: tên của máy ảo trên KVM

`file /var/lib/libvirt/qemu/org.qemu.guest_agent.0.instance-00000003.sock`

Kết quả:

`/var/lib/libvirt/qemu/org.qemu.guest_agent.0.instance-00000003.sock: socket`

Kiểm tra kết nối tới máy ảo

`virsh qemu-agent-command instance-00000003 '{"execute":"guest-ping"}'`

Kết quả:

`{"return":{}}`

Sinh password mới `Password_new#@!`

`echo -n "Password_new#@!" | base64`

Kết quả:

`dGhhb2RlcHRyYWk=`

Chèn password mới vào máy ảo, lưu ý máy ảo phải đang bật

`virsh  qemu-agent-command instance-00000003 '{ "execute": "guest-set-user-password","arguments": { "crypted": false,"username": "root","password": "dGhhb2RlcHRyYWk=" } }'`

Kết quả:

`{"return":{}}`

Thử đăng nhập vào máy ảo với password mới là `Password_new#@!`


# Đổi thông tin DA cả CentOS6 và CentOS7

```sh
# Login vào Server 

# Check IP Public server `ip a`
cd /usr/local/directadmin/scripts
./ipswap.sh 192.168.122.36 <ip-public-server>

# Reboot
init 6 

# Kiểm tra thông tin và đăng nhập 
cat /usr/local/directadmin/scripts/*.txt

# Truy cập http://<ip-public-server>:2222
```

# Đổi thông tin IP WHM
``` sh
# Update license Cpanel
/usr/local/cpanel/cpkeyclt

# CentOS6
192.168.122.109
# Replace IP
Example: 
replace 123.30.145.16 103.28.36.104 -- /var/cpanel/mainip
replace 123.30.145.16 103.28.36.104 -- /etc/hosts
replace 123.30.145.16 103.28.36.104 -- /etc/wwwacct.conf
replace 123.30.145.16 103.28.36.104 -- /usr/local/apache/conf/httpd.conf

# CentOS6
```
IP=$(ip a | grep 255 | awk '{print $2}' | cut -d '/' -f1)

<VirtualHost 192.168.122.109:443 127.0.0.1:443 *:443> /usr/local/apache/conf/httpd.conf
ADDR 192.168.122.109 /etc/wwwacct.conf
192.168.122.109		cpanel.localhost.localdomain cpanel /etc/hosts
192.168.122.109 /var/cpanel/mainip
# Restart Services
service named restart
service httpd restart
```


# CentOS7 
```
<VirtualHost 192.168.122.109:443 127.0.0.1:443 *:443> /usr/local/apache/conf/httpd.conf
ADDR 192.168.122.39 /etc/wwwacct.conf
192.168.122.39		cpanel.localhost.localdomain cpanel /etc/hosts
192.168.122.39 /var/cpanel/mainip
```

# Restart Services
systemctl restart named
ssystemctl restart httpd
# Reboot server
init 6 

# Edit hostname if not match
File /etc/wwwacct.conf
Example:
HOST share62-r3.nhanhoa.com
# Reboot server
```

Truy cập 
- WHM: https://<ip-public-server>:2083
- Client: https://<ip-public-server>:2087
- Mail: https://<ip-public-server>:2095

# Đổi thông tin IP Plesk 

Đổi thông tin IP Plesk

![](images/Plesk change IP.png)

![](images/Plesk change IP.png)

Đổi thông tin password của MSSQL



Đổi thông tin password đăng nhập Plesk

```
https://support.plesk.com/hc/en-us/articles/115001761193-How-to-change-the-IP-address-of-Plesk-server-

https://docs.plesk.com/en-US/12.5/advanced-administration-guide-win/system-maintenance/changing-ip-addresses.49727/
```


Truy cập 
- Plesk: https://<ip-public-server>:2083

# Sử dụng Qemu để đóng image 

``` sh
qemu-img convert -c /tmp/centos62.img -O qcow2 CentOS6-Blank-2018.img
```

