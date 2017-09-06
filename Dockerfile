FROM phpmyadmin/phpmyadmin:4.7.0-2

ARG TZ=UTC

RUN apk upgrade --update && \
    apk add tzdata && cp /usr/share/zoneinfo/$TZ /etc/timezone && apk del tzdata
