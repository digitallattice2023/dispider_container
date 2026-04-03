#!/usr/bin/env bash
set -e

# 权限修复
sudo chown -R user:user /home/user/task
sudo chmod -R 755 /home/user/task

# 初始化 per-worker 持久化数据目录
sudo mkdir -p /home/user/data
sudo chown -R user:user /home/user/data
sudo chmod -R 755 /home/user/data

# 调度模式判断
if [ -n "$SCHEDULE" ]; then
    echo "=========================================="
    echo "  定时模式：SCHEDULE=$SCHEDULE"
    echo "=========================================="

    # 构建 crontab 条目（继承所有环境变量）
    env | grep -v '^_=' | sed 's/^\(.*\)$/export \1/' > /tmp/cron_env.sh
    cat > /tmp/crontab_entry << CRON_EOF
$SCHEDULE /bin/bash -c 'source /tmp/cron_env.sh && /usr/local/bin/python /home/user/task/main.py >> /home/user/data/schedule.log 2>&1'
CRON_EOF

    # 安装 crontab
    crontab /tmp/crontab_entry

    echo "首次立即执行..."
    /usr/local/bin/python /home/user/task/main.py 2>&1 | tee -a /home/user/data/schedule.log

    echo "进入定时循环，使用 cron 前台模式..."
    # cron 需要 root 权限启动，然后保持前台
    sudo cron -f
else
    echo "=========================================="
    echo "  一次性模式：直接执行 main.py"
    echo "=========================================="
    /usr/local/bin/python /home/user/task/main.py

    echo "脚本执行完毕，保持容器运行..."
    tail -f /dev/null
fi
