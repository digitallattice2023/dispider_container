# ============================================================
# dispider 4.3.0 — 使用 Selkies-GStreamer (WebRTC) 替代 x11vnc + noVNC
# 相比 4.2.0 的变化：
#   - 移除 x11vnc / noVNC / websockify
#   - 新增 GStreamer + selkies-gstreamer (WebRTC 远程桌面)
#   - 新增 PulseAudio (音频流支持)
#   - 新增 xdotool / xclip (键鼠输入 & 剪贴板同步)
#   - 不再需要 customize_novnc.sh (selkies 原生支持自适应缩放)
# 优势：更低延迟、原生动态分辨率、剪贴板、音频支持
# ============================================================

# ==================== 第一阶段：编译 Python 3.12 ====================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 更换 APT 源为阿里云镜像
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list

USER root

# 安装编译依赖并编译 Python
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    sqlite3 \
    libsqlite3-dev

RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz \
    && tar -xf Python-3.12.0.tgz \
    && cd Python-3.12.0 \
    && ./configure --enable-loadable-sqlite-extensions --enable-optimizations \
    && make -j $(nproc) \
    && make altinstall

# 安装 pip 并安装所有 Python 包（应用代码使用）
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && /usr/local/bin/python3.12 get-pip.py \
    && rm get-pip.py \
    && /usr/local/bin/pip3.12 install --no-cache-dir \
       setuptools \
       wheel \
       pandas \
       numpy \
       fake-useragent \
       dispider==3.0.4 \
       bs4 \
       loguru \
       tqdm \
       xlrd \
       openpyxl \
       requests \
       patchright


# ==================== 第二阶段：运行时镜像 ====================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

# 复制 Python 3.12 二进制文件、库和 site-packages（应用代码使用）
COPY --from=builder /usr/local/bin/python3.12 /usr/local/bin/
COPY --from=builder /usr/local/bin/pip3.12 /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# 创建符号链接，让 python 和 pip 指向 Python 3.12
RUN rm -f /usr/local/bin/python \
 && ln -s /usr/local/bin/python3.12 /usr/local/bin/python \
 && ln -s /usr/local/bin/pip3.12 /usr/local/bin/pip \
 && ln -s /usr/local/bin/pip3.12 /usr/local/bin/pip3

# 更换 APT 源为阿里云镜像
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list

#
# 安装基础依赖 + Xfce 桌面 + GStreamer + Selkies 运行依赖 + 浏览器依赖
#
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ---- 常见工具 ----
    bzip2 \
    gnupg \
    gnupg2 \
    curl \
    wget \
    ca-certificates \
    sudo \
    dbus-x11 \
    x11-xserver-utils \
    xfonts-base \
    x11-utils \
    git \
    net-tools \
    # ---- Xfce 桌面 ----
    xfce4 \
    xfce4-goodies \
    # ---- Xvfb: 虚拟 X 服务器 ----
    xvfb \
    # ---- 本地化支持 ----
    locales \
    # ---- 图标主题 & 中文字体 ----
    hicolor-icon-theme \
    adwaita-icon-theme-full \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-noto-cjk \
    # ---- Playwright/Patchright 浏览器运行依赖 ----
    libnss3 \
    libgbm1 \
    libasound2 \
    libnspr4 \
    # ---- GStreamer 核心与插件 (Selkies-GStreamer 依赖) ----
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-gl \
    gstreamer1.0-pulseaudio \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    # ---- GObject Introspection / Python GStreamer 绑定 ----
    gir1.2-gst-plugins-base-1.0 \
    gir1.2-gstreamer-1.0 \
    # ---- 系统 Python3 (Selkies 必须使用系统 Python 运行) ----
    python3 \
    python3-pip \
    python3-dev \
    python3-gi \
    python3-gst-1.0 \
    python3-setuptools \
    python3-wheel \
    # ---- 输入处理 (Selkies 键鼠映射) ----
    xdotool \
    xclip \
    # ---- 音频 (PulseAudio → WebRTC 音频流) ----
    pulseaudio \
    # ---- 光标/X11 工具 ----
    x11-apps \
    && fc-cache -fv \
    && rm -rf /var/lib/apt/lists/*

#
# 配置中文语言环境
#
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

#
# 安装 selkies-gstreamer (使用系统 Python3，因为依赖 python3-gi / python3-gst-1.0)
# 注意：这里用 python3 -m pip 确保装到系统 Python 环境
#
RUN python3 -m pip install --no-cache-dir selkies-gstreamer

#
# 安装 Selkies-GStreamer Web 前端
# 从 GitHub 仓库克隆，只取 addons/gst-web 目录
#
RUN git clone --single-branch --depth 1 https://github.com/selkies-project/selkies-gstreamer.git /tmp/selkies-src && \
    cp -r /tmp/selkies-src/addons/gst-web /opt/gst-web && \
    rm -rf /tmp/selkies-src

#
# 复制启动脚本
#
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 安装 Patchright 浏览器
RUN python -m patchright install chrome

# 创建非 root 用户并设置 sudo 权限
RUN useradd -m -s /bin/bash -G sudo user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

# 创建用户目录
RUN mkdir -p /home/user/Desktop && \
    chown -R user:user /home/user

# 创建任务目录和 patchright 组件目录
RUN mkdir -p /home/user/task
RUN mkdir -p /home/user/patchright_components
RUN chown -R user:user /home/user/task && chmod -R 755 /home/user/task
ENV PLAYWRIGHT_BROWSERS_PATH=/home/user/patchright_components

# 设置目录权限
RUN chown -R user:user /opt/gst-web && \
    chmod 755 /start.sh && \
    chmod 1777 /tmp

# ---- 暴露端口 ----
# Selkies-GStreamer Web 端口 (WebRTC 信令 + Web 前端)
EXPOSE 8080

# ---- 语言/时区环境变量 ----
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai

# ---- 显示环境变量 ----
ENV DISPLAY=:1
ENV LIBGL_ALWAYS_INDIRECT=1

# ---- Selkies-GStreamer 配置 ----
# 使用 x264enc 软件编码器（无需 GPU）
ENV SELKIES_ENCODER=x264enc
# Web 前端文件路径
ENV SELKIES_WEB_ROOT=/opt/gst-web
# 关闭基本认证（容器内部网络访问，可按需开启）
ENV SELKIES_ENABLE_BASIC_AUTH=false
# 启用动态分辨率调整（浏览器窗口大小变化时自动适配）
ENV SELKIES_ENABLE_RESIZE=true

# ---- PulseAudio 配置 ----
ENV PULSE_SERVER=unix:/tmp/pulse-socket
ENV XDG_RUNTIME_DIR=/tmp/runtime-user

# 切换到非 root 用户
USER user

# 设置工作目录
WORKDIR /home/user/task

# 启动入口
CMD ["/start.sh"]
