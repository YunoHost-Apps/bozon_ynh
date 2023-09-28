#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

#=================================================
# PERSONAL HELPERS
#=================================================

# Clean & copy files needed to final folder
myynh_clean_source () {
    find "$install_dir" -type f -name ".htaccess" -delete
    if [ -e "$install_dir/.gitignore" ]; then
        ynh_secure_remove --file="$install_dir/.gitignore"
    fi
}

# Convert --data to --data-urlencode before ynh_local_curl
myynh_urlencode() {
    local data
    if [[ $# != 1 ]]; then
        echo "Usage: $0 string-to-urlencode"
        return 1
    fi
    data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
    if [[ $? != 3 ]]; then
        echo "Unexpected error" 1>&2
        return 2
    fi
    echo "${data##/?}"
    return 0
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
