# Cài đặt Plesk 

Cài đặt 
```sh
# Sử dụng screen để cài đặt 
screen -S Plesk

# Cài đặt Plesk 
sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O - https://autoinstall.plesk.com/one-click-installer)

# Để thoát màn hình screen
Ctrl + A + D

# Để login lại màn hình screen cài đặt DA 
screen -rd Plesk

# Sau khi cài đặt xong xóa file cài đặt
rm -rf latest installer.lock

```

Truy cập 
- Plesk: https://<ip-public-server>:8443