#!/usr/bin/env sh
set -e

DB_HOST="${DATABASE_HOST:-localhost}"
echo "Waiting for postgres at ${DB_HOST}:5432..."
until pg_isready -h "${DB_HOST}" -p 5432 -U postgres >/dev/null 2>&1; do
  sleep 1
done

mix deps.get
mix ecto.create
mix ecto.migrate

(cd ui && pnpm install && pnpm dev --host 0.0.0.0) &
exec mix run --no-halt
