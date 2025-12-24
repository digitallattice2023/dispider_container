# 选择 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04  AS builder

# 避免交互式安装中断
ENV DEBIAN_FRONTEND=noninteractive

# 更换 APT 源为阿里云镜像
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list


USER root
# 安装编译依赖并编译Python
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
    libsqlite3-dev  # 添加了 sqlite3 和 libsqlite3-dev


RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz \
    && tar -xf Python-3.12.0.tgz \
    && cd Python-3.12.0 \
    && ./configure  --enable-loadable-sqlite-extensions --enable-optimizations \
    && make -j $(nproc) \
    && make altinstall

# 安装 pip 并安装所有 Python 包
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


FROM ubuntu:22.04

# 避免交互式安装中断
ENV DEBIAN_FRONTEND=noninteractive


USER root

# 复制 Python 二进制文件、库和 site-packages
COPY --from=builder /usr/local/bin/python3.12 /usr/local/bin/
COPY --from=builder /usr/local/bin/pip3.12 /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# 4. 创建符号链接，让 python 和 pip 指向对应的 Python3.12 版本
#
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
# 安装基础依赖 + Xfce 桌面 + VNC/noVNC + 编译 Python 所需依赖 + 图标主题 + Playwright 浏览器依赖 + SSH服务
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    # 常见工具
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
    # 安装 xdpyinfo 工具
    x11-utils \
    # Xfce 桌面
    xfce4 \
    xfce4-goodies \
    # Xvfb: 虚拟 X 服务器，用于无显卡环境
    xvfb \
    # x11vnc: 提供 VNC 访问
    x11vnc \
    # noVNC 需要的 websockify
    git \
    # 本地化支持
    locales \
    # 图标主题（修复文件夹/目录图标为空的问题）
    hicolor-icon-theme \
    adwaita-icon-theme-full \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-noto-cjk \
    # Playwright 浏览器运行所需的系统依赖（根据错误信息添加）
    libnss3 \
    libgbm1 \
    libasound2 \
    libnspr4 \
    # SSH服务器
    openssh-server \
    && fc-cache -fv \
    # 安装完后清理
    && rm -rf /var/lib/apt/lists/*

#
# 配置中文语言环境
#
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

#
# 5. 安装 noVNC 到 /opt/novnc
#
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify.git /opt/novnc/utils/websockify && \
    ln -s /opt/novnc/vnc_lite.html /opt/novnc/index.html


COPY customize_novnc.sh /customize_novnc.sh
RUN chmod +x /customize_novnc.sh
RUN /customize_novnc.sh

#
# 6. 准备启动脚本 (start.sh)
#    - 启动 Xvfb -> 设置 DISPLAY -> x11vnc -> Xfce4 -> noVNC

COPY start.sh /start.sh
RUN chmod +x /start.sh

# 创建非root用户并设置sudo权限
RUN useradd -m -s /bin/bash -G sudo user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user && \
    # 设置user用户密码为dispider（可自行修改）
    echo 'user:dispider' | chpasswd

# 配置SSH服务
RUN mkdir -p /var/run/sshd && \
    # 允许密码登录
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # 允许user用户登录
    echo 'AllowUsers user' >> /etc/ssh/sshd_config

# 创建用户的Desktop目录并复制应用程序快捷方式
RUN mkdir -p /home/user/Desktop && \
    # 设置所有权限为user用户
    chown -R user:user /home/user

# 创建任务目录并设置公共patchright组件目录
RUN mkdir -p /home/user/task
RUN mkdir -p /home/user/patchright_components
RUN chown -R user:user /home/user/task && chmod -R 755 /home/user/task
ENV PLAYWRIGHT_BROWSERS_PATH=/home/user/patchright_components

# 修改必要目录的权限
RUN chown -R user:user /opt/novnc && \
    chmod 755 /start.sh && \
    chmod 1777 /tmp

# 暴露 noVNC 访问端口
EXPOSE 8080
# 暴露 VNC 原生服务端口
EXPOSE 5900
# 暴露 SSH 端口
EXPOSE 22

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai

# 设置显示环境变量
ENV DISPLAY=:1
ENV LIBGL_ALWAYS_INDIRECT=1
ENV XDG_RUNTIME_DIR=/tmp

# 切换到非root用户
USER user

# 设置工作目录为用户的task目录
WORKDIR /home/user/task

# 进入容器时默认执行 start.sh
CMD ["/start.sh"]

