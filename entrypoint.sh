#!/bin/ash

set -eo pipefail

# c.f. https://github.com/actions/checkout/issues/760
git config --global --add safe.directory "$GITHUB_WORKSPACE"
merged_commit_sha=$(php get-merged-commit-sha.php)

echo "Base branch: ${GITHUB_BASE_REF}"
echo "Head branch: ${GITHUB_HEAD_REF}"
echo "Merged CSHA: ${merged_commit_sha}"

#cat "${GITHUB_EVENT_PATH}"

git fetch --depth=1 origin +refs/heads/*:refs/heads/* || true

git log --no-merges --graph --oneline --decorate "origin/${GITHUB_BASE_REF}..$(git branch --show-current)" | \
tac | \
grep -o '[a-f0-9]\{7,11\}' | \
head -n 1 | \
xargs -I '{}' git rev-parse "{}^"

echo "${merged_commit_sha}" | \
grep -o '[a-f0-9]\{7,11\}' | \
head -n 1 | \
xargs -I '{}' git rev-parse "{}^"

/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${merged_commit_sha}:composer.lock" --with-links --with-platform --no-dev -vvv > /workdir/production.md
production=$(cat /workdir/production.md)
/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${merged_commit_sha}:composer.lock" --with-links --with-platform --no-prod -vvv > /workdir/development.md
development=$(cat /workdir/development.md)

echo "Raw:"
echo "=================================================="
echo "Production:"
echo "${production}"
echo "--------------------------------------------------"
echo "Development:"
echo "${development}"

php /workdir/post-process.php production
php /workdir/post-process.php development

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
  php /workdir/comment.php production "🏰 Composer Production Dependency changes 🏰"
  php /workdir/comment.php development "🚧 Composer Development Dependency changes 🚧"
fi
