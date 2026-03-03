# 处理阶段
FROM docker.code.firfe.work/node:22.22.0-alpine3.23 AS build

# 系统 npm 换源 安装软件
RUN npm config set registry https://registry.npmmirror.com && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    sed -i 's/https:/http:/g' /etc/apk/repositories && \
    apk update && apk add --no-cache nginx openssl

# 复制代码
COPY 代码 /app
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

# 安装依赖
RUN cd /app/server && npm ci --only=production

# 自签证书
RUN mkdir -p /app/certificate && \
    openssl req -x509 -newkey rsa:4096 \
      -keyout /app/certificate/cert.key \
      -out /app/certificate/cert.pem \
      -days 3660 \
      -nodes \
      -subj "/C=CN/ST=State/L=City/O=Organization/CN=localhost"
# 设置权限
RUN chmod -R 777 /app

FROM docker.code.firfe.work/node:22.22.0-alpine3.23

# 设置源，安装 nginx
RUN npm config set registry https://registry.npmmirror.com && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    sed -i 's/https:/http:/g' /etc/apk/repositories && \
    apk update && apk add --no-cache nginx

# 复制代码

COPY --from=build /app /app

ENTRYPOINT ["/app/docker-entrypoint.sh"]

# 暴露端口
EXPOSE 80 443

LABEL 原项目地址="https://github.com/redTreeOnWall/memorains"
LABEL 镜像制作者="https://space.bilibili.com/17547201"
LABEL GitHub主页="https://github.com/Firfr/memorains"
LABEL Gitee主页="https://gitee.com/firfe/memorains"

# docker buildx build --platform linux/amd64 --tag firfe/memorains:0.8.66 --load .
# docker buildx build --platform linux/arm64 --tag firfe/memorains:0.8.66-arm64 --load .
