#!/bin/sh
# 在目标系统内执行：修复 CA 证书、清除 root 临时密码、强制过期、写入 /etc/issue

# ==========================================
# 1. 修复缺失的 CA 证书
# ==========================================
if ! dpkg -s ca-certificates >/dev/null 2>&1; then
    echo "ca-certificates is missing, fixing apt sources temporarily..."
    sed -i 's|https://|http://|g' /etc/apt/sources.list.d/debian.sources
    apt-get update -qq >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates >/dev/null 2>&1 || true
    update-ca-certificates >/dev/null 2>&1 || true
    sed -i 's|http://|https://|g' /etc/apt/sources.list.d/debian.sources
    apt-get update -qq >/dev/null 2>&1 || true
fi

# ==========================================
# 2. 删除 root 的临时密码，并强制首次登录修改
# ==========================================
passwd -d root >/dev/null 2>&1 || true
passwd -e root >/dev/null 2>&1 || true

if grep -q 'nullok_secure' /etc/pam.d/common-auth 2>/dev/null; then
    sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
fi

IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP_ADDR" ] && IP_ADDR="DHCP Not Ready"

cat <<EOF > /root/INSTALL_INFO.txt
Root Password: (empty, will be set on first login)
IP Address:    $IP_ADDR
EOF
chmod 600 /root/INSTALL_INFO.txt

cat <<EOF > /etc/issue

#####################################################
  Debian First Boot Setup
  Root Password: (empty)
  You must set a new password on first login.
  IP Address:    $IP_ADDR
#####################################################

EOF
cp /etc/issue /etc/issue.net