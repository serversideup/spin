# Learn more about the Server Side Up PHP Docker Images at:
# https://serversideup.net/open-source/docker-php/

FROM serversideup/php:beta-8.3-fpm-nginx as base

FROM base as development

# Fix permission issues in development by setting the "www-data"
# user to the same user and group that is running docker.
ARG USER_ID
ARG GROUP_ID
RUN if getent group $GROUP_ID ; then \
        NEW_GROUP_ID="9$GROUP_ID" ; \
        groupmod -g $NEW_GROUP_ID $(getent group $GROUP_ID | cut -d: -f1) && \
        groupmod -g $GROUP_ID www-data ; \
        usermod -g $GROUP_ID www-data ; \
    else \
        groupadd -g $GROUP_ID www-data ; \
    fi && \
    usermod -u $USER_ID www-data

FROM base as deploy
COPY --chown=www-data:www-data . /var/www/html