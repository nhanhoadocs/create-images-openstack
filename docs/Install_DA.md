# Cài đặt cấu hình DA

4.1 Cài đặt DA
```sh
# Sử dụng screen để cài đặt 
screen -S DA

# Cài đặt epel và update các bản cập nhật mới cho OS
yum install epel-release perl wget  -y 
yum update -y 

# Tải bản cài đặt từ DirectAdmin 
wget http://www.directadmin.com/setup.sh

# Phân quyền cho file cài đặt 
chmod +x setup.sh 

# Cài đặt
./latest

# Để thoát màn hình screen
Ctrl + A + D
# Để login lại màn hình screen cài đặt DA 
screen -rd DA

# Sau khi cài đặt xong xóa file cài đặt 
rm -rf setup.sh
```

4.2 Cấu hình DA

Sau khi cài đặt DA tiến hành cấu hình cho DA trước khi đóng Template

- Chuyển PHP version vể 5.6 
```

```

- Security DA
```

```

- Chỉnh cấu hình DA
```

```

- Create Secure /tmp cho DA
```

```

