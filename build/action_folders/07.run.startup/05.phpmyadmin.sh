#!/bin/bash

: ${WWW_UID:?"Environment variable 'WWW_UID' not defined in '${BASH_SOURCE[0]}'"}

[ -e /etc/phpmyadmin/config.user.inc.php ] || touch /etc/phpmyadmin/config.user.inc.php

if [ "${PMA_PASSWORD_FILE:-}" ]; then
    cat << EOT > /etc/phpmyadmin/config.password.inc.php
<?php
\$cfg['Servers'][\$i]['password'] = '$(< "$PMA_PASSWORD_FILE")';
?>
EOT
fi

if [ ! -f /etc/phpmyadmin/config.secret.inc.php ] ; then
    date +%s > /dev/urandom
    cat << EOT > /etc/phpmyadmin/config.secret.inc.php
<?php
\$cfg['blowfish_secret'] = "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' | fold -w 32 | head -n 1 || :)";
?>
EOT
fi
