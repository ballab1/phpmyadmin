#!/bin/bash

find /var/log -type d -exec chmod 777 '{}' \;
find /var/log -type f ! -name '.*' -exec chmod 666 '{}' \; 