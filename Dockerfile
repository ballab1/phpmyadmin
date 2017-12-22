FROM alpine:3.6

ARG TZ="America/New_York"
ARG MYSQL_PASSWORD="${CFG_MYSQL_PASSWORD}"
ARG MYSQL_ROOT_PASSWORD="${CFG_MYSQL_ROOT_PASSWORD}"
ARG MYSQL_USER="${CFG_MYSQL_USER}"

ENV VERSION=1.0.0 \
    TZ="America/New_York" \
    MYSQL_PASSWORD="${CFG_MYSQL_PASSWORD}" \
    MYSQL_ROOT_PASSWORD="${CFG_MYSQL_ROOT_PASSWORD}" \
    MYSQL_USER="${CFG_MYSQL_USER}"

LABEL version=$VERSION

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/*

# We expose phpMyAdmin on port 80
#EXPOSE 80

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["phpmyadmin"]
