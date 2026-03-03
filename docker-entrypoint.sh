#!/bin/sh
set -e

LOG_DIR="/var/log/nginx"
MAX_SIZE_MB=3
MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))

if [ ! -d "$LOG_DIR" ]; then
    echo "错误: 目录 $LOG_DIR 不存在!"
    mkdir -p "$LOG_DIR"
fi

echo "开始检查 $LOG_DIR 下的日志文件 (阈值: ${MAX_SIZE_MB}MB)..."
find "$LOG_DIR" -maxdepth 1 -name "*.log" -type f | while read -r logfile; do
    
    if command -v stat >/dev/null 2>&1; then
        FILE_SIZE=$(stat -c %s "$logfile" 2>/dev/null)
        if [ -z "$FILE_SIZE" ]; then
            FILE_SIZE=$(stat -f %z "$logfile" 2>/dev/null)
        fi
    else
        FILE_SIZE=$(wc -c < "$logfile")
    fi

    if [ -z "$FILE_SIZE" ]; then
        echo "警告: 无法获取 $logfile 的大小，跳过。"
        continue
    fi

    if [ "$FILE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
        echo "发现大文件: $logfile (当前大小: $((FILE_SIZE / 1024 / 1024))MB)"
        > "$logfile"
        echo "已清空: $logfile"
    fi
done

# 捕获信号进行优雅退出
cleanup() {
    echo "正在关闭服务..."
    # 停止 Nginx
    if [ -f /tmp/nginx.pid ]; then
        kill -QUIT $(cat /tmp/nginx.pid) 2>/dev/null || true
    fi
    # 停止 Node
    if [ -n "$NODE_PID" ] && kill -0 "$NODE_PID" 2>/dev/null; then
        kill -TERM "$NODE_PID" 2>/dev/null || true
        wait "$NODE_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

echo "启动 Nginx..."
nginx -c /app/nginx.conf

echo "启动 Node.js..."
cd /app/server && node build/index.js &
NODE_PID=$!

# 等待 Node 进程
wait $NODE_PID
