FROM elixir:1.16.3-alpine

ARG PLEROMA_VER=stable
ARG UID=911
ARG GID=911
ENV MIX_ENV=prod

# 更新并安装必要的依赖
RUN apk update && apk upgrade && \
    apk add --no-cache \
        git gcc g++ musl-dev make cmake file-dev \
        exiftool imagemagick libmagic ncurses \
        postgresql-client ffmpeg openssl-dev

# 创建用户和组
RUN addgroup -g ${GID} pleroma && \
    adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

# 创建必要的目录并设置权限
ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma ${DATA}/uploads ${DATA}/static && \
    chown -R pleroma:pleroma /etc/pleroma ${DATA}

# 切换到 pleroma 用户
USER pleroma
WORKDIR /pleroma

# 克隆 Pleroma 仓库并切换到指定版本
RUN git clone -b stable https://git.pleroma.social/pleroma/pleroma.git . && \
    git checkout ${PLEROMA_VER} && \
    echo "import Mix.Config" > config/prod.secret.exs && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix release --path /pleroma

# 复制配置文件
COPY ./config.exs /etc/pleroma/config.exs

# 暴露端口
EXPOSE 4000

# 设置入口点
ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
