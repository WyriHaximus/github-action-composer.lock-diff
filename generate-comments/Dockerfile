# syntax=docker/dockerfile:experimental
FROM wyrihaximusnet/php:8.2-nts-alpine-slim-dev-root AS install-dependencies
RUN mkdir /workdir
COPY ./composer.json /workdir
COPY ./composer.lock /workdir
COPY ./entrypoint.sh /workdir
COPY ./post-process.php /workdir
COPY ./comment.php /workdir
WORKDIR /workdir
RUN composer install --ansi --no-progress --no-interaction --prefer-dist
ENTRYPOINT ["/workdir/entrypoint.sh"]
