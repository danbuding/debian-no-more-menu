#!/bin/bash
# 首次开机运行的总控脚本
exec < /dev/tty1 > /dev/tty1 2>&1

clear
echo "=========================================="
echo " Welcome! System is doing first boot setup..."
echo " Root password is EMPTY. You will be"
echo " forced to set a new password on login."
echo "=========================================="
sleep 3

# 询问是否建用户
/usr/local/bin/ask-user.sh

echo
echo "Setup complete. Press [ENTER] to clear screen and login..."
read -r

# 清理密码横幅
> /etc/issue
> /etc/issue.net

# 清理自身服务
systemctl disable firstboot.service 2>/dev/null || true
rm -f /etc/systemd/system/firstboot.service
rm -f /usr/local/bin/firstboot.sh
rm -f /usr/local/bin/ask-user.sh

clear