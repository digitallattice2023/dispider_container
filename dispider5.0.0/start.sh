#!/usr/bin/env bash
set -e

sudo chown -R user:user /home/user/task
sudo chown -R user:user /home/user/patchright_components
sudo chmod -R 755 /home/user/task
sudo chmod -R 755 /home/user/patchright_components

echo "Starting SSH service ..."
# 启动SSH服务
sudo service ssh start
sleep 1

echo "Starting Xvfb ..."
# 清理旧的锁文件并以指定分辨率启动虚拟X服务器
sudo rm -rf /tmp/.X1-lock
sudo Xvfb :1 -screen 0 1920x1080x24 &
sleep 1

echo "Setting DISPLAY to :1"
# 设置DISPLAY环境变量，以便应用程序知道在哪个屏幕上显示
export DISPLAY=:1

echo "Starting x11vnc with dynamic resolution ..."
# 启动x11vnc，允许通过VNC连接到Xvfb会话
sudo x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -scale_cursor 1 -xrandr &
sleep 1

echo "Starting Xfce4 session ..."
# 启动Xfce4桌面环境
dbus-launch xfce4-session &
sleep 2 # 增加等待时间，确保桌面环境完全加载

# 自动打开终端，执行Python脚本，然后启动一个可交互的bash shell
# 这样既能看到脚本输出，又能获得一个可以操作的终端
echo "Opening terminal, executing python script, and starting an interactive shell..."
xfce4-terminal -e 'bash -c "/usr/local/bin/python /home/user/task/main.py; exec bash"' &

echo "Starting noVNC on port 8080 ..."
# 启动noVNC代理，将web请求转发到VNC服务器
cd /opt/novnc
./utils/novnc_proxy --vnc localhost:5900 --listen 8080