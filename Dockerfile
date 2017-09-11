FROM phpmyadmin/phpmyadmin:4.7.0-2

ARG TZ=UTC

RUN set -e \
    && apk update \
    && apk add tzdata \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && apk del tzdata
