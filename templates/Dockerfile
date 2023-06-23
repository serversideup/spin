FROM serversideup/php:8.2-fpm-nginx as base

# Copy the application
FROM base as deploy
COPY --chown=9999:9999 . /var/www/html