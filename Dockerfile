FROM elixir:1.16.3-alpine

ARG PLEROMA_VER=stable
ARG UID=911
ARG GID=911
ENV MIX_ENV=prod

RUN apk update &&  \
    apk add --no-cache \
        git gcc g++ musl-dev make cmake file-dev \
        exiftool imagemagick libmagic ncurses \
        postgresql-client ffmpeg openssl-dev

RUN addgroup -g ${GID} pleroma && \
    adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma ${DATA}/uploads ${DATA}/static && \
    chown -R pleroma:pleroma /etc/pleroma ${DATA}

USER pleroma
WORKDIR /pleroma

# 克隆 Pleroma 仓库并切换到指定版本
RUN git clone -b stable https://git.pleroma.social/pleroma/pleroma.git . && \
    git checkout ${PLEROMA_VER} \
    && echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mix release --path /pleroma

COPY ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
