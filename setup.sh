#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ -e .env ]; then
  printf '%s\n' '.env ja existe; nenhuma senha foi alterada.'
  exit 0
fi
command -v openssl >/dev/null 2>&1 || { echo 'Instale openssl primeiro.' >&2; exit 1; }
umask 077
# Nao utiliza credenciais do tunel nem as imprime no terminal.
DB_PASSWORD=$(openssl rand -hex 32)
ROOT_PASSWORD=$(openssl rand -hex 32)
sed -e "s/^MYSQL_PASSWORD=.*/MYSQL_PASSWORD=$DB_PASSWORD/" \
    -e "s/^MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD/" \
    .env.example > .env
chmod 600 .env
printf '%s\n' '.env criado com senhas aleatorias. Ajuste SITE_URL antes de iniciar.'
