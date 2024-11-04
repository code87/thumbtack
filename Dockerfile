FROM elixir:1.17.2-alpine

ENV VIX_COMPILATION_MODE=PLATFORM_PROVIDED_LIBVIPS

RUN apk --update add --no-cache \
    build-base \
    git \
    inotify-tools \
    libstdc++ \
    openssl \
    ncurses-dev \
    postgresql16-client \
    libc-dev \
    vips-dev \
    vips-heif 

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./

CMD ["sh", "-c", "mix deps.get && mix deps.compile && /bin/sh"]
