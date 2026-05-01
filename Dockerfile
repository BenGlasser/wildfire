FROM elixir:1.19.5

WORKDIR /app

ENV MIX_ENV=dev
ENV ERL_AFLAGS="-kernel shell_history enabled"
ENV CI=true

RUN apt-get update && apt-get install --yes build-essential inotify-tools postgresql-client bash curl \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install --yes nodejs \
  && npm install -g pnpm \
  && rm -rf /var/lib/apt/lists/*

COPY mix.exs mix.lock* ./
RUN mix deps.get

COPY ui/package.json ui/pnpm-lock.yaml* ui/
RUN cd ui && pnpm install

COPY . .

EXPOSE 4000 5173

RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
