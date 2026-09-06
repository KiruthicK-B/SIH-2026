#!/bin/bash
set -euo pipefail

if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
  echo "Creating databases: $POSTGRES_MULTIPLE_DATABASES"
  IFS=',' read -ra DBS <<< "$POSTGRES_MULTIPLE_DATABASES"
  for db in "${DBS[@]}"; do
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
      SELECT 'CREATE DATABASE "$db"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
      GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$POSTGRES_USER";
EOSQL
  done
fi
