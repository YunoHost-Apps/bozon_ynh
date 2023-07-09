#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

#REMOVEME? php_dependencies="php$YNH_DEFAULT_PHP_VERSION-zip php$YNH_DEFAULT_PHP_VERSION-curl php$YNH_DEFAULT_PHP_VERSION-gd"

# dependencies used by the app (must be on a single line)
#REMOVEME? pkg_dependencies="$php_dependencies"

#=================================================
# PERSONAL HELPERS
#=================================================

# Check if directory/file already exists (path in argument)
myynh_check_path () {
	[ -z "$1" ] && ynh_die --message="No argument supplied"
	[ ! -e "$1" ] || ynh_die --message="$1 already exists"
}

# Create directory only if not already exists (path in argument)
myynh_create_dir () {
	[ -z "$1" ] && ynh_die --message="No argument supplied"
	[ -d "$1" ] || mkdir -p "$1"
}

# Clean & copy files needed to final folder
myynh_clean_source () {
	find "$tmpdir" -type f -name ".htaccess" | xargs rm
	[ -e "$tmpdir/.gitignore" ] && ynh_secure_remove "$tmpdir/.gitignore"
}

myynh_set_permissions () {
	[ $(find "$install_dir" -type f | wc -l) -gt 0 ] && find "$install_dir" -type f | xargs chmod 0644
	[ $(find "$install_dir" -type d | wc -l) -gt 0 ] && find "$install_dir" -type d | xargs chmod 0755
	[ $(find "$data_dir" -type f | wc -l) -gt 0 ] && find "$data_dir" -type f | xargs chmod 0644
	[ $(find "$data_dir" -type d | wc -l) -gt 0 ] && find "$data_dir" -type d | xargs chmod 0755
	chmod -R o-rwx "$install_dir"
	chown -R $app:www-data "$install_dir"
	chmod -R o-rwx "$data_dir"
	chown -R $app:www-data "$data_dir"
}

#Convert --data to --data-urlencode before ynh_local_curl
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
