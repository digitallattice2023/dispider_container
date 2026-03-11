#!/usr/bin/env bash
set -e

# ============================================================
# dispider 4.3.0 启动脚本
# 使用 Selkies-GStreamer (WebRTC) 替代 x11vnc + noVNC
# ============================================================

# ---- 修复目录权限（挂载卷可能改变 owner）----
sudo chown -R user:user /home/user/task
sudo chown -R user:user /home/user/patchright_components
sudo chmod -R 755 /home/user/task
sudo chmod -R 755 /home/user/patchright_components

# ---- 清理上次运行残留，防止容器重启后黑屏 ----
echo "Cleaning up stale files from previous run ..."
sudo rm -rf /tmp/.X1-lock /tmp/.X11-unix /tmp/.ICE-unix
sudo rm -rf /tmp/dbus-* /tmp/xfce4-* /tmp/.xfsm-*
rm -rf /home/user/.cache/sessions/*
rm -rf /home/user/.config/xfce4/sessions/*
rm -rf /home/user/.dbus/

# ---- 创建 XDG_RUNTIME_DIR (PulseAudio / D-Bus 需要) ----
export XDG_RUNTIME_DIR=/tmp/runtime-user
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# ---- 启动 PulseAudio (音频流支持) ----
echo "Starting PulseAudio ..."
pulseaudio -D --exit-idle-time=-1 --log-level=error \
    --load="module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket" \
    || echo "PulseAudio start failed (non-fatal, audio will be unavailable)"
export PULSE_SERVER=unix:/tmp/pulse-socket
sleep 0.5

# ---- 启动 Xvfb (虚拟 X 服务器) ----
echo "Starting Xvfb ..."
sudo Xvfb :1 -screen 0 1920x1080x24 +extension RANDR &
sleep 1

echo "Setting DISPLAY to :1"
export DISPLAY=:1
export LIBGL_ALWAYS_SOFTWARE=1

# ---- 关闭 xfwm4 合成器，防止 Xvfb 下 GLX 崩溃 ----
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

# ---- 启动 Xfce4 桌面环境 ----
echo "Starting Xfce4 session ..."
dbus-launch xfce4-session &
sleep 2

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

# ---- 自动打开终端并执行 Python 脚本 ----
echo "Opening terminal, executing python script, and starting an interactive shell..."
xfce4-terminal -e 'bash -c "/usr/local/bin/python /home/user/task/main.py; exec bash"' &

# ---- 启动 Selkies-GStreamer (WebRTC 远程桌面) ----
echo "Starting Selkies-GStreamer on port 8080 ..."
echo "  Encoder:    ${SELKIES_ENCODER:-x264enc}"
echo "  Web Root:   ${SELKIES_WEB_ROOT:-/opt/gst-web}"
echo "  Basic Auth: ${SELKIES_ENABLE_BASIC_AUTH:-false}"
echo "  Resize:     ${SELKIES_ENABLE_RESIZE:-true}"
echo ""
echo "Open http://<host-ip>:8080 in your browser to access the desktop."
echo ""

# selkies-gstreamer 作为前台主进程运行
# 配置通过环境变量传入 (见 Dockerfile 中的 ENV 定义)
# 也可在此通过 CLI 参数覆盖，例如:
#   --enable_basic_auth=true --basic_auth_password=yourpassword
exec selkies-gstreamer \
    --addr=0.0.0.0 \
    --port=8080
