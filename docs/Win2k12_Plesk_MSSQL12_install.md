# Cài đặt Plesk trên Windows Server 2k12

Các bước cài đặt và đóng Images
- Trên KVM node cài đặt Windows Server 2k12 
- Active Windows
- Update 
- Add Roles và Feature support cho WIndows
- Mở Remote Desktop 
- Cài đặt Plesk 
- Cài đặt MSSQL 2k12 
- Trên Plesk kết nối MSSQL
- Đóng Images

## Bước 1: Cài đặt Windows Server 2k12r2 trên KVM node.

[Hướng dẫn](Windows-2012-64bit-2018.md)

**NOTE**
Active key cho Windows và tiến hành Update full cho Windows

Reboot Server

## Bước 2: Install Requirement Roles
Add các roles và Feature cần thiết cho Server
![](../images/Plesk_install/Install_roles.png)
![](../images/Plesk_install/Install_role01.jpg)
![](../images/Plesk_install/Install_role02.jpg)
![](../images/Plesk_install/Install_role03.jpg)
![](../images/Plesk_install/Install_role04.jpg)
![](../images/Plesk_install/Install_role05.jpg)
![](../images/Plesk_install/Install_role06.jpg)
![](../images/Plesk_install/Install_role07.jpg)
![](../images/Plesk_install/Install_role08.jpg)

TIến hành Update thêm 1 lần nữa và Reboot lại Server

## Bước 3: Cài đặt Plesk

Truy cập [Plesk Download](https://installer-win.plesk.com/plesk-installer.exe) tải file cài đặt về. Tiến hành cài đặt như bình thường. 

Tạo 1 tài khoản Trial và email key trial sẽ gửi về email với nội dung tương tự
```sh
Web Host Edition 
A00S00-TGWA04-DG2B88-370E68-1V9J38
Valid until October 9, 2018
	
Web Pro Edition
A00700-837T04-JSMN88-E47N68-CE5J34
Valid until October 9, 2018

Web Admin Edition
A00300-5SKN04-B8NY88-Y74568-GW7931
Valid until October 9, 2018
```

## Bước 4: Cài đặt MSSQL
![](../images/Plesk_install/MSSQL01.png)
![](../images/Plesk_install/MSSQL02.png)
![](../images/Plesk_install/MSSQL03.png)
![](../images/Plesk_install/MSSQL04.png)
![](../images/Plesk_install/MSSQL05.png)
![](../images/Plesk_install/MSSQL06.png)
![](../images/Plesk_install/MSSQL07.png)
![](../images/Plesk_install/MSSQL08.png)
![](../images/Plesk_install/MSSQL09.png)
![](../images/Plesk_install/MSSQL10.png)
![](../images/Plesk_install/MSSQL11.png)
![](../images/Plesk_install/MSSQL12.png)
![](../images/Plesk_install/MSSQL13.png)
![](../images/Plesk_install/MSSQL14.png)
![](../images/Plesk_install/MSSQL15.png)
![](../images/Plesk_install/MSSQL16.png)
![](../images/Plesk_install/MSSQL17.png)
![](../images/Plesk_install/MSSQL18.png)
![](../images/Plesk_install/MSSQL19.png)
![](../images/Plesk_install/MSSQL20.png)
![](../images/Plesk_install/MSSQL21.png)
![](../images/Plesk_install/MSSQL22.png)
![](../images/Plesk_install/MSSQL23.png)

## Bước 5: Setup Plesk 
![](../images/Plesk_install/Plesk_crack01.png)
![](../images/Plesk_install/Plesk_crack02.png)
![](../images/Plesk_install/Plesk_crack03.png)
![](../images/Plesk_install/Plesk_crack04.png)
![](../images/Plesk_install/Plesk_crack05.png)
![](../images/Plesk_install/Plesk_crack06.png)
![](../images/Plesk_install/Plesk_crack07.png)
![](../images/Plesk_install/Plesk_crack08.png)
![](../images/Plesk_install/Plesk_crack09.png)
![](../images/Plesk_install/Plesk_crack10.png)
![](../images/Plesk_install/Plesk_crack11.png)
![](../images/Plesk_install/Plesk_crack12.png)
![](../images/Plesk_install/Plesk_crack13.png)
![](../images/Plesk_install/Plesk_crack14.png)
![](../images/Plesk_install/Plesk_crack15.png)
![](../images/Plesk_install/Plesk_crack16.png)

## Bước 7: Kết nối Plesk vào MSSQL
![](../images/Plesk_install/Plesk_MSSQL01.png)
![](../images/Plesk_install/Plesk_MSSQL02.png)
![](../images/Plesk_install/Plesk_MSSQL03.png)
![](../images/Plesk_install/Plesk_MSSQL04.png)

## Hoàn tất cài đặt 