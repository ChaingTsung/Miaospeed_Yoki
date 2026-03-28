#!/bin/bash

# =================================================
# Miaospeed 一键自动部署/更新脚本 (全架构适配版)
# =================================================

# 您的 GitHub 仓库信息
REPO="ChaingTsung/Miaospeed_Yoki"
BIN_DIR="/opt/miaospeed"
BIN_PATH="$BIN_DIR/miaospeed"
SVC_PATH="/etc/systemd/system/miaospeed.service"

echo "================================================="
echo "开始一键安装/更新 Miaospeed (自动识别架构版)"
echo "================================================="

# 1. 自动识别 CPU 架构
ARCH=$(uname -m)
echo "检测到系统物理架构: $ARCH"

case "$ARCH" in
    x86_64 | amd64 )
        TARGET_ARCH="amd64"
        ;;
    aarch64 | arm64 )
        TARGET_ARCH="arm64" # 完美适配 RK3588, RK3568, 树莓派等 64位 ARM
        ;;
    armv7l | armv8l | arm )
        TARGET_ARCH="arm"   # 适配老旧 32位 ARM 设备或 32位 系统
        ;;
    mips | mipsel | mipsle )
        TARGET_ARCH="mipsle"# 适配常见的 OpenWrt 软路由
        ;;
    *)
        echo "❌ 暂不支持的架构: $ARCH"
        exit 1
        ;;
esac

FILENAME="miaospeed_linux_${TARGET_ARCH}"
echo "匹配到的对应文件为: $FILENAME"

# 2. 确保目录存在
sudo mkdir -p $BIN_DIR

# 3. 从 GitHub 下载最新版
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$FILENAME"
echo "正在从 GitHub 下载最新版本..."

# 下载并覆盖现有文件
sudo curl -L -o $BIN_PATH "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "❌ 下载失败，请检查网络连通性或 GitHub 访问情况。"
    exit 1
fi

# 赋予执行权限
sudo chmod +x $BIN_PATH
echo "✅ 二进制文件下载并配置成功！"

# 4. 检测并自动创建 systemd 服务
if [ ! -f "$SVC_PATH" ]; then
    echo "未检测到 systemd 服务，正在自动创建..."
    sudo cat <<EOF > $SVC_PATH
[Unit]
Description=Miaospeed Server
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5
# 启动命令：默认监听本地 11223 端口，如需白名单限制请在末尾加上 -allowip 参数
ExecStart=$BIN_PATH server -bind 127.0.0.1:11223 -path miaospeed -token coity.app -mtls
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd 并设置开机自启
    sudo systemctl daemon-reload
    sudo systemctl enable miaospeed
    echo "✅ systemd 服务创建并配置完毕！"
else
    echo "⚡ 检测到现有的 systemd 服务，保留原有配置跳过创建。"
fi

# 5. 重启服务以应用新版本
echo "正在重启 Miaospeed 服务..."
sudo systemctl restart miaospeed

echo "================================================="
echo "🎉 部署完成！当前运行状态如下："
sudo systemctl status miaospeed --no-pager | grep "Active:"
echo "================================================="