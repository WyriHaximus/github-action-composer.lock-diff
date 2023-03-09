#!/bin/bash

set -eo pipefail

branchPoint=$(
  git log --no-merges --graph --oneline --decorate origin/main..$(git branch --show-current) | \
  tac | \
  grep -o '[a-f0-9]\{7,11\}' | \
  head -n 1 | \
  xargs -I '{}' git rev-parse "{}^"
)


# c.f. https://github.com/actions/checkout/issues/760
git config --global --add safe.directory "$GITHUB_WORKSPACE"

echo "Base branch: ${GITHUB_BASE_REF}"
echo "Base point branch: ${branchPoint}"
echo "Head branch: ${GITHUB_HEAD_REF}"

git show $branchPoint:composer.lock | cat > "/tmp/branch-point-composer.lock"

./vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" --with-links --with-platform --no-dev -vvv > ./production.md
production=$(cat ./production.md)
./vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" /tmp/branch-point-composer.lock --with-links --with-platform --no-prod -vvv > ./development.md
development=$(cat ./development.md)

echo "Raw:"
echo "=================================================="
echo "Production:"
echo "${production}"
echo "--------------------------------------------------"
echo "Development:"
echo "${development}"

php ./post-process.php production
php ./post-process.php development

echo "Post Processed:"
echo "=================================================="
echo "Production:"
echo "${production}"
echo "--------------------------------------------------"
echo "Development:"
echo "${development}"

delimiter="$(openssl rand -hex 8)"
echo "production<<${delimiter}" >> "${GITHUB_OUTPUT}"
echo "$production" >> "${GITHUB_OUTPUT}"
echo "${delimiter}" >> "${GITHUB_OUTPUT}"

delimiter="$(openssl rand -hex 8)"
echo "development<<${delimiter}" >> "${GITHUB_OUTPUT}"
echo "$development" >> "${GITHUB_OUTPUT}"
echo "${delimiter}" >> "${GITHUB_OUTPUT}"


if [ "$INPUT_DRYRUN" != "yes" ]
then
  echo "No in a dry run so upserting comments when desirable"
  php ./comment.php production "🏰 Composer Production Dependency changes 🏰"
  php ./comment.php development "🚧 Composer Development Dependency changes 🚧"
fi
