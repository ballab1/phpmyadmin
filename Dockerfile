ARG FROM_BASE=openjdk:20180314
FROM $FROM_BASE 

# name and version of this docker image
ARG CONTAINER_NAME=phpmyadmin
ARG CONTAINER_VERSION=1.0.0

LABEL org_name=$CONTAINER_NAME \
      version=$CONTAINER_VERSION 

# set to non zero for the framework to show verbose action scripts
ARG DEBUG_TRACE=0


ARG MYSQL_PASSWORD="${CFG_MYSQL_PASSWORD}"
ARG MYSQL_ROOT_PASSWORD="${CFG_MYSQL_ROOT_PASSWORD}"
ARG MYSQL_USER="${CFG_MYSQL_USER}"


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME"
RUN [ $DEBUG_TRACE != 0 ] || rm -rf /tmp/* 


# We expose phpMyAdmin on port 80
#EXPOSE 80


ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["phpmyadmin"]
