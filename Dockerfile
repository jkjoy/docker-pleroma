FROM elixir:1.15.8-otp-24-alpine

ARG PLEROMA_VER=stable
ARG UID=911
ARG GID=911
ENV MIX_ENV=prod

RUN apk update && apk upgrade && \
    apk add --no-cache \
        git gcc g++ musl-dev make cmake file-dev \
        exiftool imagemagick libmagic ncurses \
        postgresql-client ffmpeg

RUN addgroup -g ${GID} pleroma && \
    adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma ${DATA}/uploads ${DATA}/static && \
    chown -R pleroma:pleroma /etc/pleroma ${DATA}

USER pleroma
WORKDIR /pleroma

# 克隆 Pleroma 仓库并切换到指定版本
RUN git clone -b stable https://git.pleroma.social/pleroma/pleroma.git . && \
    git checkout ${PLEROMA_VER}

# 配置 Mix 并构建 Release
RUN echo "import Mix.Config" > config/prod.secret.exs

# 逐步安装依赖并构建 Release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix release --path /pleroma

COPY ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
