#!/bin/bash

: ${WWW_UID:?"Environment variable 'WWW_UID' not defined in '${BASH_SOURCE[0]}'"}

if [ ! -f /etc/phpmyadmin/config.secret.inc.php ] ; then

    cat << EOT > /etc/phpmyadmin/config.secret.inc.php
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT

fi

[ -e /etc/phpmyadmin/config.user.inc.php ] || touch /etc/phpmyadmin/config.user.inc.php
