# 选择 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04 AS builder

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
    libsqlite3-dev

RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz \
    && tar -xf Python-3.12.0.tgz \
    && cd Python-3.12.0 \
    && ./configure --enable-loadable-sqlite-extensions --enable-optimizations \
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
       lxml \
       fake-useragent \
       dispider==3.0.4 \
       bs4 \
       loguru \
       tqdm \
       xlrd \
       openpyxl \
       requests \
       patchright \
       nest_asyncio \
       aiofiles


# ==================== 精简运行期 ====================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

# 复制 Python 二进制文件、库和 site-packages
COPY --from=builder /usr/local/bin/python3.12 /usr/local/bin/
COPY --from=builder /usr/local/bin/pip3.12 /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# 创建符号链接
RUN rm -f /usr/local/bin/python \
 && ln -s /usr/local/bin/python3.12 /usr/local/bin/python \
 && ln -s /usr/local/bin/pip3.12 /usr/local/bin/pip \
 && ln -s /usr/local/bin/pip3.12 /usr/local/bin/pip3

# 更换 APT 源为阿里云镜像
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list

# 安装最小运行依赖（无桌面环境、无 VNC、无 noVNC）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    curl \
    wget \
    ca-certificates \
    sudo \
    # 本地化支持
    locales \
    # cron 定时调度
    cron \
    # 中文字体
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    # Patchright/Chrome 运行依赖
    libnss3 \
    libgbm1 \
    libasound2 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libpango-1.0-0 \
    libcairo2 \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# 配置中文语言环境
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# 准备启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 创建非root用户并设置sudo权限
RUN useradd -m -s /bin/bash -G sudo user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

# 创建任务目录并设置公共patchright组件目录（必须在安装浏览器前完成）
RUN mkdir -p /home/user/task && \
    mkdir -p /home/user/patchright_components && \
    chown -R user:user /home/user/task && \
    chmod -R 755 /home/user/task

# 设置浏览器路径（必须在 install 前声明，否则装到 root 默认缓存）
ENV PLAYWRIGHT_BROWSERS_PATH=/home/user/patchright_components

# 安装 Patchright 浏览器（chromium 供 headless 采集，chrome 供需要完整渲染的场景）
RUN python -m patchright install chromium chrome && \
    chown -R user:user /home/user/patchright_components

RUN chmod 1777 /tmp

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV TZ=Asia/Shanghai

# 切换到非root用户
USER user

# 设置工作目录为用户的task目录
WORKDIR /home/user/task

# 进入容器时默认执行 start.sh
CMD ["/start.sh"]
