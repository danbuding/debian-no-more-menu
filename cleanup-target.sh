#!/bin/bash
# 在目标系统内执行，用于清理安装介质并调整 UEFI 启动顺序

if [ -d /sys/firmware/efi ]; then
    echo "检测到 UEFI 环境，正在调整启动项顺序..."
    DEBIAN_BOOT=$(efibootmgr | grep -i 'debian' | head -n1 | sed 's/Boot\([0-9A-Fa-f]*\).*/\1/')
    if [ -n "$DEBIAN_BOOT" ]; then
        OTHERS=$(efibootmgr | grep '^Boot[0-9A-Fa-f]' | grep -v -i 'debian' | sed 's/Boot\([0-9A-Fa-f]*\).*/\1/' | paste -sd, -)
        if [ -n "$OTHERS" ]; then
            efibootmgr -o "${DEBIAN_BOOT},${OTHERS}" >/dev/null 2>&1 || true
        else
            efibootmgr -o "${DEBIAN_BOOT}" >/dev/null 2>&1 || true
        fi
        echo "UEFI 启动顺序已更新，Debian 已设为第一启动项。"
    fi
fi

ROOT_DISK=$(lsblk -no pkname $(findmnt -n -o SOURCE /) 2>/dev/null | head -n1)
echo "当前系统盘为: $ROOT_DISK"

for dev in /sys/block/sd* /sys/block/sr* /sys/block/vd*; do
    [ -e "$dev" ] || continue
    DEV_NAME=$(basename "$dev")
    
    if [ "$DEV_NAME" != "$ROOT_DISK" ]; then
        echo "正在强制断开并注销安装介质: $DEV_NAME"
        eject "/dev/$DEV_NAME" 2>/dev/null || true
        echo 1 > "$dev/device/delete" 2>/dev/null || true
    fi
done