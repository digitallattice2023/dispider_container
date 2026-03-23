#!/usr/bin/env bash
set -e

sudo chown -R user:user /home/user/task
sudo chown -R user:user /home/user/patchright_components
sudo chmod -R 755 /home/user/task
sudo chmod -R 755 /home/user/patchright_components

# 初始化 per-worker 持久化数据目录
sudo mkdir -p /home/user/data
sudo chown -R user:user /home/user/data
sudo chmod -R 755 /home/user/data

echo "Starting SSH service ..."
# 启动SSH服务
sudo service ssh start
sleep 1

echo "Cleaning up stale files from previous run ..."
# 清理旧的 X11、D-Bus、Xfce4 会话残留文件（容器重启时文件系统会保留这些）
sudo rm -rf /tmp/.X1-lock /tmp/.X11-unix /tmp/.ICE-unix
sudo rm -rf /tmp/dbus-* /tmp/xfce4-* /tmp/.xfsm-*
# 清理 Xfce4 会话恢复数据（根因：session manager 保存的崩溃状态会导致重启后黑屏）
rm -rf /home/user/.cache/sessions/*
rm -rf /home/user/.config/xfce4/sessions/*
# 清理 D-Bus stale session 地址文件
rm -rf /home/user/.dbus/

echo "Starting Xvfb ..."
# 以指定分辨率启动虚拟X服务器
sudo Xvfb :1 -screen 0 1920x1080x24 &
sleep 1

echo "Setting DISPLAY to :1"
# 设置DISPLAY环境变量，以便应用程序知道在哪个屏幕上显示
export DISPLAY=:1
export LIBGL_ALWAYS_SOFTWARE=1

# 关闭 xfwm4 合成器（Xvfb 下 GLX 可能不稳定，重启后会导致 xfwm4 崩溃进而黑屏）
XFWM4_CONFIG="/home/user/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
mkdir -p /home/user/.config/xfce4/xfconf/xfce-perchannel-xml
if [ -f "$XFWM4_CONFIG" ]; then
		sed -i 's/\(<property name="use_compositing" type="bool" value="\)true"/\1false"/' "$XFWM4_CONFIG" || true
else
		cat > "$XFWM4_CONFIG" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
	<property name="general" type="empty">
		<property name="use_compositing" type="bool" value="false"/>
	</property>
</channel>
EOF
fi

echo "Starting x11vnc with dynamic resolution ..."
# 启动x11vnc，允许通过VNC连接到Xvfb会话
sudo x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -scale_cursor 1 -xrandr &
sleep 1

echo "Starting Xfce4 session ..."
# 启动Xfce4桌面环境
dbus-launch xfce4-session &
sleep 2 # 增加等待时间，确保桌面环境完全加载

# 兜底：若会话恢复异常导致关键进程未启动，手动拉起
if ! pgrep -x xfwm4 >/dev/null; then
	echo "xfwm4 未启动，使用 --compositor=off 兜底拉起"
	xfwm4 --compositor=off --replace >/tmp/xfwm4.log 2>&1 &
	sleep 1
fi

if ! pgrep -x xfdesktop >/dev/null; then
	echo "xfdesktop 未启动，兜底拉起"
	xfdesktop >/tmp/xfdesktop.log 2>&1 &
	sleep 1
fi

if ! pgrep -x xfce4-panel >/dev/null; then
	echo "xfce4-panel 未启动，兜底拉起"
	xfce4-panel >/tmp/xfce4-panel.log 2>&1 &
fi

# 自动打开终端，执行Python脚本，然后启动一个可交互的bash shell
# 这样既能看到脚本输出，又能获得一个可以操作的终端
echo "Opening terminal, executing python script, and starting an interactive shell..."
if [ -n "$SCHEDULE" ]; then
    echo "定时模式启用：SCHEDULE=$SCHEDULE"
    env | grep -v '^_=' | sed 's/^\(.*\)$/export \1/' > /tmp/cron_env.sh
    cat > /tmp/crontab_entry << CRON_EOF
$SCHEDULE /bin/bash -c 'source /tmp/cron_env.sh && DISPLAY=:1 /usr/local/bin/python /home/user/task/main.py >> /home/user/data/schedule.log 2>&1'
CRON_EOF
    crontab /tmp/crontab_entry
    sudo cron
    xfce4-terminal -e 'bash -c "/usr/local/bin/python /home/user/task/main.py; echo 定时模式已激活，后续执行见 /home/user/data/schedule.log; exec bash"' &
else
    xfce4-terminal -e 'bash -c "/usr/local/bin/python /home/user/task/main.py; exec bash"' &
fi

echo "Starting noVNC on port 8080 ..."
# 启动noVNC代理，将web请求转发到VNC服务器
cd /opt/novnc
./utils/novnc_proxy --vnc localhost:5900 --listen 8080