#!/bin/ash

set -eo pipefail

# c.f. https://github.com/actions/checkout/issues/760
git config --global --add safe.directory "$GITHUB_WORKSPACE"
merged_commit_sha=$(php get-merged-commit-sha.php)

echo "Base branch: ${GITHUB_BASE_REF}"
echo "Head branch: ${GITHUB_HEAD_REF}"
echo "Merged CSHA: ${merged_commit_sha}"

git fetch --depth=1 origin +refs/heads/*:refs/heads/* || true
curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" $(curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${GITHUB_REPOSITORY}/git/trees/${merged_commit_sha}" | jq -r '.tree[]  | select(.path == "composer.lock") | .url') | jq -r '.content' | base64 -d > "/tmp/${merged_commit_sha}-composer.lock"
cat "/tmp/${merged_commit_sha}-composer.lock"

/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "/tmp/${merged_commit_sha}-composer.lock" --with-links --with-platform --no-dev -vvv > /workdir/production.md
production=$(cat /workdir/production.md)
/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "/tmp/${merged_commit_sha}-composer.lock" --with-links --with-platform --no-prod -vvv > /workdir/development.md
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
