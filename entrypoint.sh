#!/bin/ash

set -eo pipefail

echo "Base branch: ${GITHUB_BASE_REF}"
echo "Head branch: ${GITHUB_HEAD_REF}"

git fetch --depth=1 origin +refs/heads/*:refs/heads/* || true

/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${GITHUB_HEAD_REF}:composer.lock" --with-links --with-platform --no-dev -vvv > /workdir/production.md
echo "Production:"
cat /workdir/production.md

if [ "$INPUT_DRYRUN" != "yes" ]
then
  echo "No in dry run so upserting production comment when desirable"
  php /workdir/comment.php production "🏰 Composer Production Dependency changes 🏰"
fi

/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${GITHUB_HEAD_REF}:composer.lock" --with-links --with-platform --no-prod -vvv > /workdir/development.md
echo "Development:"
cat /workdir/development.md

if [ "$INPUT_DRYRUN" != "yes" ]
then
  echo "No in dry run so upserting development comment when desirable"
  php /workdir/comment.php development "🚧 Composer Development Dependency changes 🚧"
fi
