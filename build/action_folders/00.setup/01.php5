#!/bin/bash

declare -ar env_phpadmin=(
    'WWW="${WWW:-/www}"'
)

lib.updateRuntimeEnvironment "${env_phpadmin[*]}" 
