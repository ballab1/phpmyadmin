#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='PHPADMIN'

export TZ='America/New_York'
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  


declare -r PHPADM_PKGS="curl tzdata php7-session php7-mysqli php7-mbstring php7-xml php7-gd php7-zlib php7-bz2 php7-zip php7-openssl php7-curl php7-opcache php7-json nginx php7-fpm supervisor"


# Nagios::Object perl module
declare -r PHPADM_VERSION=${PHPADM_VERSION:-'4.7.4'}  
declare -r PHPADM_FILE="phpMyAdmin-${PHPADM_VERSION}-all-languages.tar.gz"
declare -r PHPADM_URL="https://files.phpmyadmin.net/phpMyAdmin/${PHPADM_VERSION}/phpMyAdmin-${PHPADM_VERSION}-all-languages.tar.gz"
declare -r PHPADM_SHA256="fd1a92959553f5d87b3a2163a26b62d6314309096e1ee5e89646050457430fd2"


#directories
declare WWW=/www 

#  groups/users
#declare www_user=${www_user:-'www-data'}
#declare www_uid=${www_uid:-82}
#declare www_group=${www_group:-'www-data'}
#declare www_gid=${www_gid:-82}
#declare nagios_user=${nagios_user:-'nagios'}
#declare nagios_uid=${nagios_uid:-1002}
#declare nagios_group=${nagios_group:-'nagios'}
#declare nagios_gid=${nagios_gid:-1002}

# global exceptions
declare -i dying=0
declare -i pipe_error=0


#----------------------------------------------------------------------------
# Exit on any error
function catch_error() {
    echo "ERROR: an unknown error occurred at $BASH_SOURCE:$BASH_LINENO" >&2
}

#----------------------------------------------------------------------------
# Detect when build is aborted
function catch_int() {
    die "${BASH_SOURCE[0]} has been aborted with SIGINT (Ctrl-C)"
}

#----------------------------------------------------------------------------
function catch_pipe() {
    pipe_error+=1
    [[ $pipe_error -eq 1 ]] || return 0
    [[ $dying -eq 0 ]] || return 0
    die "${BASH_SOURCE[0]} has been aborted with SIGPIPE (broken pipe)"
}

#----------------------------------------------------------------------------
function die() {
    local status=$?
    [[ $status -ne 0 ]] || status=255
    dying+=1

    printf "%s\n" "FATAL ERROR" "$@" >&2
    exit $status
}  

#############################################################################
function cleanup()
{
    printf "\nclean up\n"
    rm -rf "${WWW}/setup/"
    rm -rf "${WWW}/examples/"
    rm -rf "${WWW}/r/"
    rm -rf "${WWW}/po/"
    rm -rf "${WWW}/composer.json"
    rm -rf "${WWW}/RELEASE-DATE-$VERSION"
}

#############################################################################
function createUserAndGroup()
{
    local -r user=$1
    local -r uid=$2
    local -r group=$3
    local -r gid=$4
    local -r homedir=$5
    local -r shell=$6
    local result
    
    local wanted=$( printf '%s:%s' $group $gid )
    local nameMatch=$( getent group "${group}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    local idMatch=$( getent group "${gid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: group/gid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"           

    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "\ncreate group:  %s\n" $group
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && groupdel "$( getent group ${group} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && groupdel "$( getent group ${gid} | awk -F ':' '{ print $1 }' )"
        /usr/sbin/groupadd --gid "${gid}" "${group}"
    fi

    
    wanted=$( printf '%s:%s' $user $uid )
    nameMatch=$( getent passwd "${user}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    idMatch=$( getent passwd "${uid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: user/uid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"    
    
    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "create user: %s\n" $user
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && userdel "$( getent passwd ${user} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && userdel "$( getent passwd ${uid} | awk -F ':' '{ print $1 }' )"

        /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
    fi
}

#############################################################################
function downloadFile()
{
    local -r name=$1
    local -r file="${name}_FILE"
    local -r url="${name}_URL"
    local -r sha="${name}_SHA256"

    printf "\nDownloading  %s\n" "${!file}"
    for i in {0..3}; do
        [[ i -eq 3 ]] && exit 1
        curl --output "${!file}" --location "${!url}"
#        wget -O "${!file}" --no-check-certificate "${!url}"
        [[ $? -ne 0 ]] && continue
        local result=$(echo "${!sha}  ${!file}" | sha256sum -cw 2>&1)
        printf "%s\n" "$result"
        [[ $result != *' WARNING: '* ]] && return
        printf "Failed to successfully download ${!file}. Retrying....\n"
    done
}

#############################################################################
function downloadFiles()
{
    cd ${TOOLS}

    downloadFile 'PHPADM'
}

#############################################################################
function fixupNginxLogDirecory()
{
    printf "\nfix default log directory for nginx\n"
    if [[ -h /var/lib/nginx ]]; then
        rm  /var/lib/nginx
    #    ln -s /var/log /var/lib/nginx
        mkdir -p /var/lib/nginx
    fi
}

#############################################################################
function header()
{
    local -r bars='+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    printf "\n\n\e[1;34m%s\nBuilding container: \e[0m%s\e[1;34m\n%s\e[0m\n" $bars $CONTAINER $bars
}
 
#############################################################################
function install_CUSTOMIZATIONS()
{
    printf "\nAdd configuration and customizations\n"

    declare -a DIRECTORYLIST="/etc /usr /opt /var"
    for dir in ${DIRECTORYLIST}; do
        [[ -d "${TOOLS}/${dir}" ]] && cp -r "${TOOLS}/${dir}/"* "${dir}/"
    done

    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh
    
    [[ -d /var/nginx/client_body_temp ]] || mkdir -p /var/nginx/client_body_temp
    [[ -d /sessions ]]                   || mkdir -p /sessions
    [[ -d /var/run/php ]]                || mkdir -p /var/run/php
    [[ -d /run/nginx ]]                  || mkdir -p /run/nginx
}

#############################################################################
function install_MYPHP_ADMIN()
{
    local -r file="$PHPADM_FILE"

    printf "\nprepare and install %s\n" "${file}"
    tar xzf "${file}" -C "${TOOLS}"
    mkdir -p "${WWW}"
    mv "${TOOLS}/phpMyAdmin-${PHPADM_VERSION}-all-languages/"* "${WWW}"
    sed -i "s@define('CONFIG_DIR'.*@define('CONFIG_DIR', '/etc/phpmyadmin/');@" "${WWW}/libraries/vendor_config.php"
}

############################################################################
function installAlpinePackages() {
    apk update
    apk add --no-cache $PHPADM_PKGS
}

#############################################################################
function installTimezone() {
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chmod u+rwx /usr/local/bin/docker-entrypoint.sh

    find "${WWW}" -type d -exec chmod 750 {} \;
    find "${WWW}" -type f -exec chmod 640 {} \;

www_user='root'
www_group='nobody'
    chown "${www_user}:${www_group}" -R "${WWW}"
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

header
declare -r MYSQL_PASSWORD="${MYSQL_PASSWORD:?'Environment variable MYSQL_PASSWORD must be defined'}"
declare -r MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?'Environment variable MYSQL_ROOT_PASSWORD must be defined'}"
declare -r MYSQL_USER="${MYSQL_USER:?'Environment variable MYSQL_USER must be defined'}"

installAlpinePackages
installTimezone
#createUserAndGroup "${www_user}" "${www_uid}" "${www_group}" "${www_gid}" "${WWW}" /sbin/nologin
#createUserAndGroup "${nagios_user}" "${nagios_uid}" "${nagios_group}" "${nagios_gid}" "${NAGIOS_HOME}" /bin/bash
downloadFiles
fixupNginxLogDirecory
install_MYPHP_ADMIN
install_CUSTOMIZATIONS
setPermissions
cleanup
exit 0
