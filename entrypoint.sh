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

diffProd=$(/workdir/vendor/bin/composer-diff "${branch}" --with-links --with-platform --no-dev -vvv)

echo "Production:"
echo "${diffProd}"

diffProd="${diffProd//'%'/'%25'}"
diffProd="${diffProd//$'\n'/'%0A'}"
diffProd="${diffProd//$'\r'/'%0D'}"

echo "::set-output name=production::$diffProd"

diffDev=$(/workdir/vendor/bin/composer-diff "${branch}" --with-links --with-platform --no-prod -vvv)

echo "Development:"
echo "${diffDev}"

diffDev="${diffDev//'%'/'%25'}"
diffDev="${diffDev//$'\n'/'%0A'}"
diffDev="${diffDev//$'\r'/'%0D'}"

echo "::set-output name=development::$diffDev"
