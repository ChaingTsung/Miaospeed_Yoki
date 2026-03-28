#!/bin/bash

bash -c '
# 1. 配置您的 GitHub 仓库信息
REPO="https://github.com/ChaingTsung/Miaospeed_Yoki.git"

# 定义路径变量
BIN_DIR="/opt/miaospeed"
BIN_PATH="$BIN_DIR/miaospeed"
SVC_PATH="/etc/systemd/system/miaospeed.service"

echo "开始更新/安装 Miaospeed..."

# 2. 确保目录存在
sudo mkdir -p $BIN_DIR

# 3. 从 GitHub 最新 Release 下载编译好的二进制文件
echo "正在从 $REPO 下载最新版本..."
sudo curl -L -o $BIN_PATH "https://github.com/$REPO/releases/latest/download/miaospeed_linux_amd64"

# 赋予执行权限
sudo chmod +x $BIN_PATH
echo "二进制文件更新成功！"

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
# 启动命令：这里沿用了您之前指定的 socket 方式及参数
ExecStart=$BIN_PATH server -bind /tmp/miaospeed.socket -path miaospeed -token coity.app -mtls
# 关键配置：确保 Nginx 可以访问到 /tmp 下的 socket
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd 并设置开机自启
    sudo systemctl daemon-reload
    sudo systemctl enable miaospeed
    echo "systemd 服务创建并配置完毕！"
else
    echo "检测到现有的 systemd 服务，跳过创建步骤。"
fi

# 5. 重启服务以应用新版本
echo "正在重启 Miaospeed 服务..."
sudo systemctl restart miaospeed

# 输出当前服务状态
echo "更新完成！当前运行状态："
sudo systemctl status miaospeed --no-pager | grep "Active:"
'