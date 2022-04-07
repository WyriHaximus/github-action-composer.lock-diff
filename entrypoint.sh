#!/bin/ash

set -eo pipefail

echo "Base branch: ${GITHUB_BASE_REF}"
echo "Head branch: ${GITHUB_HEAD_REF}"

git fetch --depth=1 origin +refs/heads/*:refs/heads/* || true

/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${GITHUB_HEAD_REF}:composer.lock" --with-links --with-platform --no-dev -vvv > /workdir/production.md
production=$(cat /workdir/production.md)
/workdir/vendor/bin/composer-diff "${GITHUB_BASE_REF}:composer.lock" "${GITHUB_HEAD_REF}:composer.lock" --with-links --with-platform --no-prod -vvv > /workdir/development.md
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

production="${production//'%'/'%25'}"
production="${production//$'\n'/'%0A'}"
production="${production//$'\r'/'%0D'}"

development="${development//'%'/'%25'}"
development="${development//$'\n'/'%0A'}"
development="${development//$'\r'/'%0D'}"

echo "::set-output name=production::$production"
echo "::set-output name=development::$development"


if [ "$INPUT_DRYRUN" != "yes" ]
then
  echo "No in a dry run so upserting comments when desirable"
  php /workdir/comment.php production "🏰 Composer Production Dependency changes 🏰"
  php /workdir/comment.php development "🚧 Composer Development Dependency changes 🚧"
fi
