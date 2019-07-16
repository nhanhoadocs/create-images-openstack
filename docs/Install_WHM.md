# Cài đặt WHM

Cài đặt 
```sh
# Sử dụng screen để cài đặt 
screen -S WHM

# Cài đặt các requirement packet 
yum install curl perl -y 

# Tải bản cài đặt về 
curl -o latest -L https://securedownloads.cpanel.net/latest

# Để thoát màn hình screen
Ctrl + A + D

# Để login lại màn hình screen cài đặt DA 
screen -rd WHM

# Sau khi cài đặt xong xóa file cài đặt
rm -rf latest
```


Truy cập 
- WHM: https://<ip-public-server>:2083
- Cpanel: https://<ip-public-server>:2087
- Mail: https://<ip-public-server>:2095
