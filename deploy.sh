#!/bin/bash

# =================================================
# Miaospeed 一键自动部署/更新脚本 (全架构适配版)
# =================================================

# ⚠️ 注意：这里只能填 "用户名/仓库名"，绝对不能带 https:// 或 .git
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
        TARGET_ARCH="arm64" 
        ;;
    armv7l | armv8l | arm )
        TARGET_ARCH="arm"   
        ;;
    mips | mipsel | mipsle )
        TARGET_ARCH="mipsle"
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
# 拼接后的正确下载地址应该是：https://github.com/ChaingTsung/Miaospeed_Yoki/releases/latest/download/miaospeed_linux_amd64
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$FILENAME"
echo "正在从 GitHub 下载最新版本: $DOWNLOAD_URL"

# 使用 curl 下载（-f 参数表示遇到 404 等 HTTP 错误时直接让 curl 报错，不保存错误网页）
sudo curl -f -L -o $BIN_PATH "$DOWNLOAD_URL"

# 检查 curl 下载是否成功
if [ $? -ne 0 ]; then
    echo "❌ 下载失败！可能是 GitHub 访问受限，或者 Release 中没有找到对应文件。"
    exit 1
fi

# 检查下载下来的文件大小是否正常（正常编译的 Go 程序肯定大于 1MB，即 1048576 字节）
FILE_SIZE=$(stat -c%s "$BIN_PATH" 2>/dev/null || stat -f%z "$BIN_PATH" 2>/dev/null)
if [ -n "$FILE_SIZE" ] && [ "$FILE_SIZE" -lt 1048576 ]; then
    echo "❌ 严重错误：下载到的文件体积异常（仅 $FILE_SIZE 字节），可能是 404 报错文本！"
    echo "请检查您的 GitHub 仓库是否为公开(Public)状态，或者 Release 链接是否正确。"
    sudo rm -f $BIN_PATH
    exit 1
fi

# 赋予执行权限
sudo chmod +x $BIN_PATH
echo "✅ 二进制文件下载并校验成功！"

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
# 启动命令：监听本地 11223 端口
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