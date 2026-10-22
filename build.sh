#!/bin/bash
# ============================================================
# Debian 13 Preseed ISO 构建脚本（增量打包，手动确认启动版）
# ============================================================

set -euo pipefail

if ! command -v xorriso &>/dev/null; then
    echo "错误：缺少命令 'xorriso'。请安装：sudo apt install xorriso"
    exit 1
fi

SOURCE_ISO="${1:-}"
if [[ -z "$SOURCE_ISO" || ! -f "$SOURCE_ISO" ]]; then
    echo "用法: $0 /path/to/debian-13.x.x-amd64-netinst.iso"
    exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# 提取引导配置文件
mkdir -p "$WORKDIR/iso"
echo "正在提取引导配置文件..."
xorriso -osirrox on -indev "$SOURCE_ISO" \
    -extract /isolinux/isolinux.cfg "$WORKDIR/iso/isolinux.cfg" \
    -extract /isolinux/menu.cfg     "$WORKDIR/iso/menu.cfg" \
    -extract /isolinux/txt.cfg      "$WORKDIR/iso/txt.cfg" \
    -extract /boot/grub/grub.cfg    "$WORKDIR/iso/grub.cfg" 2>/dev/null || true

chmod -R +w "$WORKDIR/iso"

ISOLINUX_CFG="$WORKDIR/iso/isolinux.cfg"
MENU_CFG="$WORKDIR/iso/menu.cfg"
TXT_CFG="$WORKDIR/iso/txt.cfg"
GRUB_CFG="$WORKDIR/iso/grub.cfg"
BOOT_MSG="$WORKDIR/iso/boot.msg"

# ================= 1. 生成 BIOS 提示文件 =================
cat > "$BOOT_MSG" <<'EOF'
==========================================================
 WARNING: THIS WILL WIPE YOUR DISK AND INSTALL DEBIAN!
 
 The system is PAUSED and waiting for your command.
 Press <ENTER> to start the automated installation.
==========================================================
EOF

# ================= 2. 覆写 isolinux.cfg =================
cat > "$ISOLINUX_CFG" <<'EOF'
prompt 1
timeout 0
default install
display /isolinux/boot.msg

label install
    menu label ^Install
    kernel /install.amd/vmlinuz
    append auto=true priority=critical preseed/file=/cdrom/preseed.cfg initrd=/install.amd/initrd.gz ipv6.disable=1 --- quiet
EOF

# 清空 menu.cfg 和 txt.cfg
> "$MENU_CFG"
> "$TXT_CFG"

# ================= 3. 覆写 grub.cfg (UEFI) =================
if [[ -f "$GRUB_CFG" ]]; then
    cat > "$GRUB_CFG" <<'EOF'
set timeout=-1
set default=0
set timeout_style=menu

# 菜单标题
menuentry "Auto Install Debian (WARNING: WIPES DISK)" {
    linux /install.amd/vmlinuz auto=true priority=critical preseed/file=/cdrom/preseed.cfg ipv6.disable=1
    initrd /install.amd/initrd.gz
}
EOF
fi

# ================= 增量打包 =================
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_ISO="${SOURCE_ISO%.iso}-${TIMESTAMP}.iso"

echo "正在使用增量模式打包..."
xorriso -indev "$SOURCE_ISO" -outdev "$OUTPUT_ISO" \
    -map preseed.cfg                       /preseed.cfg \
    -map aliyun-debian.sources             /aliyun-debian.sources \
    -map firstboot.sh                      /firstboot.sh \
    -map ask-user.sh                       /ask-user.sh \
    -map firstboot.service                 /firstboot.service \
    -map setup-root.sh                     /setup-root.sh \
    -map cleanup-target.sh                 /cleanup-target.sh \
    -map "$BOOT_MSG"                       /isolinux/boot.msg \
    -map "$ISOLINUX_CFG"                   /isolinux/isolinux.cfg \
    -map "$MENU_CFG"                       /isolinux/menu.cfg \
    -map "$TXT_CFG"                        /isolinux/txt.cfg \
    -map "$GRUB_CFG"                       /boot/grub/grub.cfg \
    -boot_image any replay \
    -volid "DEBIAN13PRESEED"

echo "============================================================"
echo "构建完成！"
echo "输出 ISO: $OUTPUT_ISO"
echo "注意：已开启绝对防误触，必须按 <ENTER> 才会开始安装。"
echo "============================================================"