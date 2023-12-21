# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/

FROM serversideup/php:beta-8.3-fpm-nginx as base

FROM base as development

# Fix permission issues in development
# by setting the "www-data" user to the same UID as
# the developer's user.
ARG USER_ID
RUN usermod -u $USER_ID www-data

FROM base as deploy
COPY --chown=www-data:www-data . /var/www/html