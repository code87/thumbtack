FROM elixir:1.17.2-alpine

ENV VIX_COMPILATION_MODE=PLATFORM_PROVIDED_LIBVIPS

RUN apk --update add --no-cache \
    build-base \
    erlang-dev \
    git \
    inotify-tools \
    libstdc++ \
    openssl \
    ncurses-dev \
    postgresql-client \
    libc-dev \
    vips-dev \
    vips-heif \
    musl-locales

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./

CMD ["sh", "-c", "mix deps.get && mix deps.compile && /bin/sh"]
