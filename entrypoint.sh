#!/bin/ash

set -eo pipefail


diffProd=$(./vendor/bin/composer-diff master --with-links --with-platform)

echo "Production:"
echo "${diffProd}"

diffProd="${diffProd//'%'/'%25'}"
diffProd="${diffProd//$'\n'/'%0A'}"
diffProd="${diffProd//$'\r'/'%0D'}"

echo "::set-output name=production::$diffProd"

diffDev=$(./vendor/bin/composer-diff master --with-links --with-platform)

echo "Development:"
echo "${diffDev}"

diffDev="${diffDev//'%'/'%25'}"
diffDev="${diffDev//$'\n'/'%0A'}"
diffDev="${diffDev//$'\r'/'%0D'}"

echo "::set-output name=development::$diffDev"
