#!/bin/bash
apt update && apt install -y wget unzip
nx=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
xpid=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)
[ -n "${ver}" ] && wget -O $nx.zip https://github.com/XTLS/Xray-core/releases/download/v${ver}/Xray-linux-64.zip
[ ! -s $nx.zip ] && wget -O $nx.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip $nx.zip && rm -f $nx.zip
chmod a+x xray && mv xray $xpid
sed -i "s/uuid/$uuid/g" ./config.json
sed -i "s/uuid/$uuid/g" /etc/nginx/nginx.conf
[ -n "${www}" ] && rm -rf /usr/share/nginx/* && wget -c -P /usr/share/nginx "https://github.com/yonggekkk/doprax-xray/raw/main/3w/html${www}.zip" && unzip -o "/usr/share/nginx/html${www}.zip" -d /usr/share/nginx/html
cat config.json | base64 > config
rm -f config.json

# argo与加密方案出自fscarmen
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
./cloudflared-linux-amd64 tunnel --url http://localhost:8080 --no-autoupdate > argo.log 2>&1 &
sleep 5
ARGO=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")
xver=`./$xpid version | sed -n 1p | awk '{print $2}'`
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4=$(curl -s4m6 api64.ipify.org -k)
v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`

doprax_xray_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"doprax_xray_vmess\",\
\"add\": \"${ARGO}\",\
\"port\": \"443\",\
\"id\": \"$uuid\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${ARGO}\",\
\"path\": \"/$uuid-vm\",\
\"tls\": \"tls\",\
\"sni\": \"${ARGO}\"\
}"\
    | base64 -w 0)" 
doprax_xray_vless="vless://${uuid}@${ARGO}:443?encryption=none&security=tls&sni=$ARGO&type=ws&host=${ARGO}&path=/$uuid-vl#doprax_xray_vless"
doprax_xray_trojan="trojan://${uuid}@${ARGO}:443?security=tls&type=ws&host=${ARGO}&path=/$uuid-tr&sni=$ARGO#doprax_xray_trojan"

cat > log << EOF
当前已安装的Xray正式版本：$xver
当前检测到的IP：$v4    地区：$v4l
==================================================
cloudflared argo 隧道模式配置如下
==================================================
vmess+ws+tls配置明文如下，相关参数可复制到客户端
服务器地址：$ARGO
端口：443
uuid：$uuid
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-vm
tls：开启
分享链接如下
${doprax_xray_vmess}
-----------------------------------------------------------------------
vless+ws+tls配置明文如下，相关参数可复制到客户端
服务器地址：$ARGO
端口：443
uuid：$uuid
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-vl
tls：开启
分享链接如下
${doprax_xray_vless}
------------------------------------------------------
trojan+ws+tls配置明文如下，相关参数可复制到客户端
服务器地址：$ARGO
端口：443
密码：$uuid
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-tr
tls：开启 
分享链接如下
${doprax_xray_trojan}
------------------------------------------------------
shadowsocks+ws+tls配置明文如下，相关参数可复制到客户端
服务器地址：$ARGO
端口：443
密码：$uuid
加密方式：chacha20-ietf-poly1305
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-ss
tls：开启
------------------------------------------------------
socks+ws+tls配置明文如下，相关参数可复制到客户端
服务器地址：$ARGO
端口：443
用户名：$uuid
密码：$uuid
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-so
tls：开启
EOF

echo "=============================================="
echo "五大节点配置信息"
echo "=============================================="
cat log
echo "=============================================="
echo "如环境支持shell，输入cat log查看当前配置"
echo "配置教程请关注-甬哥侃侃侃-"
echo "=============================================="

nginx
base64 -d config > config.json; ./$xpid -config=config.json
