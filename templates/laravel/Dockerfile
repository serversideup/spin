FROM serversideup/php:beta-8.3-fpm-nginx as base

FROM base as deploy
COPY --chown=www-data:www-data . /var/www/html