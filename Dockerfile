ARG FROM_BASE=openjdk:20180217
FROM $FROM_BASE 


ARG MYSQL_PASSWORD="${CFG_MYSQL_PASSWORD}"
ARG MYSQL_ROOT_PASSWORD="${CFG_MYSQL_ROOT_PASSWORD}"
ARG MYSQL_USER="${CFG_MYSQL_USER}"


# version of this docker image
ARG CONTAINER_VERSION=1.0.2
LABEL version=$CONTAINER_VERSION 


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/container/build.sh \
    && /tmp/container/build.sh 'PHPADMIN'
RUN rm -rf /tmp/* 


# We expose phpMyAdmin on port 80
#EXPOSE 80

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["phpmyadmin"]
