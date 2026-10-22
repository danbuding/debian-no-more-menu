# 🚀 Debian 13 极速无人值守定制镜像构建套件

这是一个用于快速构建 **Debian 13 (Trixie)** 定制化安装 ISO 的自动化脚本集合。

抛弃了繁琐的图形化安装、动辄半小时的安全补丁下载，以及境外源的龟速。它能在几分钟内装出一个极致纯净、开箱即用的底层 VPS 环境。

## ✨ 核心特性

- **⏸️ 防误触设计**：开机后无限期暂停在引导界面，**必须手动按 `<Enter>`** 才会开始安装，避免误刷机。
- **⚡ 极致精简极速**：跳过 `standard` 任务集，仅安装基础系统与 `openssh-server`，砍掉上千个无用包，下载不过百兆，几分钟内秒装完毕。
- **🇨🇳 彻底本土化**：全程使用阿里云镜像源（安装期间纯 HTTP 极速，安装后自动切回 HTTPS 安全源），自动配置中国上海时区。
- **🔒 零密码且绝对安全**：安装完毕 root 默认无密码。首次 SSH 或控制台登录时，系统**强制要求设置新密码**。
- **🖥️ 交互式 First Boot**：首次开机自动接管屏幕，询问是否创建普通用户（自动赋予 sudo 权限）。
- **🔌 暴力拔除安装介质**：安装完成重启时，自动清理 UEFI NVRAM 启动项，并强制注销光驱/U盘，彻底告别“无限循环安装”。
- **📦 无损增量打包**：构建脚本采用 `xorriso` 增量替换技术，生成的 ISO 完美保留原版结构，体积与原版一致，且带有时间戳防缓存。

---

## 📂 文件结构

```text
├── build.sh                 # 核心构建脚本，自动解压、注入、重新打包
├── preseed.cfg              # Debian 安装器的自动化应答文件
├── setup-root.sh            # 安装收尾阶段执行：修证书、强删临时密码、写登录横幅
├── firstboot.sh             # 首次开机执行的总控脚本（清理自身、调用交互）
├── ask-user.sh              # 首次开机交互：询问并创建普通用户
├── firstboot.service        # 触发 First Boot 的 systemd 服务
├── cleanup-target.sh        # 清理 UEFI 启动项并强制断开光驱/安装 U 盘
└── aliyun-debian.sources    # 阿里云 APT 源（deb822 格式）
```

---

## 🛠️ 快速开始

### 1. 环境准备

确保你的构建机（推荐 Debian/Ubuntu）已安装以下依赖：

```bash
sudo apt update
sudo apt install -y xorriso isolinux gzip cpio
```

### 2. 准备官方镜像

从 [Debian 官网](https://www.debian.org/download) 或国内镜像站下载官方的 `debian-13.x.x-amd64-netinst.iso`，放到当前目录。

### 3. 一键构建

赋予脚本执行权限并运行：

```bash
chmod +x build.sh
./build.sh debian-13.x.x-amd64-netinst.iso
```

构建成功后，你将获得一个形如 `debian-13.x.x-amd64-netinst-20231024-142035.iso` 的定制镜像。

---

## 🚀 安装与使用体验

1. **引导启动**：将 ISO 挂载到虚拟机或刻录至 U 盘。开机后屏幕会显示警告信息并**无限期停留**。
2. **开始安装**：手动按下 `Enter` 键。系统将一路静默自动完成分区、下载和安装，期间自动调整 UEFI 启动顺序并拔出光驱。
3. **首次登录**：重启进入系统后，屏幕会显示 root 密码为空。
4. **强制改密**：输入用户名 `root`，密码直接回车。系统会立刻拦截并强制要求你设置新密码。
5. **建普通用户**：设置完 root 密码后，系统会提示 `Create a regular user?`，按提示输入 `y`、用户名（如 `openwrt`）和密码，系统将自动为其分配 sudo 权限。

---

## 🔬 核心技术原理解析 (踩坑记录)

- **如何跳过菜单并暂停？** 
  对于 BIOS，重写 `isolinux.cfg` 并设置 `timeout 0`，加上 `boot.msg` 提示；对于 UEFI，直接覆写 `grub.cfg` 并设置 `timeout=-1`。以此实现绝对等待。
- **如何解决证书报错？** 
  由于跳过了 `standard`，系统会缺失 CA 证书。`setup-root.sh` 会在安装结束时检测并临时切换到 HTTP 源，安装 `ca-certificates`，再无缝切回 HTTPS。
- **为什么安装完不会循环启动？** 
  `cleanup-target.sh` 会在重启前调用 `efibootmgr` 将硬盘排到第一顺位，并利用内核的 `/sys/block/xxx/device/delete` 接口，瞬间物理注销虚拟光驱或 U 盘，逼迫主板从硬盘启动。
- **为什么 root 密码强制为空？** 
  为了防止安装器卡死，`preseed` 塞入了一个 `dummy` 临时密码。随后在 `late_command` 中，执行 `passwd -d root` 和 `passwd -e root` 将密码清空并强制过期，从而实现了首次登录必须设密的安全机制。

---

## ⚠️ 注意事项

- **安全性**：首次开机前，请勿将物理机或虚拟机暴露在公网环境。
- **网络要求**：安装期间需要能正常访问 DHCP 和阿里云镜像站，暂不支持纯离线安装。
- **Ventoy 兼容性**：此方案使用了原生引导，请在 Ventoy 中使用“Normal Mode”引导，或直接使用 `dd` 模式写入 U 盘。

---
*Created with 🐟 & 🍻 by 蓝色大肥鱼*
