FROM alpine:3.6

ENV VERSION=1.0.0
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
