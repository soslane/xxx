#!/bin/bash

clear
echo "=================================================="
echo "      VLESS + REALITY + TCP 交互式安装脚本"
echo "=================================================="

# 0. 交互式获取自定义参数
read -p "请输入自定义端口 [直接回车将随机生成安全高端口]: " PORT
if [ -z "$PORT" ]; then
    # 如果用户直接回车（输入为空），则在 10000 到 65000 之间随机生成一个端口
    PORT=$(shuf -i 10000-65000 -n 1)
    echo -e "\033[33m-> 已自动为你生成随机端口: $PORT\033[0m"
fi

read -p "请输入伪装域名 (SNI) [默认 www.microsoft.com]: " SNI
SNI=${SNI:-www.microsoft.com}

echo "--------------------------------------------------"
echo "准备安装... 端口: $PORT | SNI: $SNI"
echo "--------------------------------------------------"

# 1. 安装/更新 Xray 核心
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 2. 生成必要参数
UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)

# 3. 写入配置文件
cat <<EOF > /usr/local/etc/xray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "$SNI:443",
                    "xver": 0,
                    "serverNames": [
                        "$SNI"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": [
                        "$SHORT_ID"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF

# 4. 重启 Xray 并设置开机自启
systemctl restart xray
systemctl enable xray

# 5. 获取本机公网 IP
IP=$(curl -s https://api64.ipify.org)

# 6. 生成节点链接
LINK="vless://$UUID@$IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#Oracle_Reality"

# 7. 输出结果
clear
echo "--------------------------------------------------"
echo "      VLESS + REALITY + TCP 安装完成"
echo "--------------------------------------------------"
echo "当前端口: $PORT (请记得在甲骨文控制台和本机防火墙放行此端口!)"
echo "UUID: $UUID"
echo "公钥 (Public Key): $PUBLIC_KEY"
echo "私钥 (Private Key): $PRIVATE_KEY"
echo "Short ID: $SHORT_ID"
echo "伪装域名 (SNI): $SNI"
echo "--------------------------------------------------"
echo "节点链接 (直接复制到客户端):"
echo ""
echo -e "\033[32m$LINK\033[0m"
echo "--------------------------------------------------"