#!/bin/ash

set -eo pipefail

if [ $(echo ${GITHUB_BASE_REF} | wc -c) -eq 1 ] ; then
  if git rev-parse --verify main > /dev/null 2>&1; then
    branch="main"
  elif git rev-parse --verify master > /dev/null 2>&1; then
    branch="master"
  fi
else
  branch="${GITHUB_BASE_REF}"
fi

echo "Found default branch: ${branch}"

git fetch --depth=1 origin +refs/heads/*:refs/heads/*

/workdir/vendor/bin/composer-diff "${branch}" --with-links --with-platform --no-dev -vvv > /workdir/production.md

echo "Production:"
cat /workdir/production.md
php /workdir/comment.php production "🏰 Composer Production Dependency changes 🏰"

/workdir/vendor/bin/composer-diff "${branch}" --with-links --with-platform --no-prod -vvv > /workdir/development.md

echo "Development:"
cat /workdir/development.md
php /workdir/comment.php development "🚧 Composer Development Dependency changes 🚧"
