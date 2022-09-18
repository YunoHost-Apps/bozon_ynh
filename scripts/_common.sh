#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

php_dependencies="php$YNH_DEFAULT_PHP_VERSION-zip php$YNH_DEFAULT_PHP_VERSION-curl php$YNH_DEFAULT_PHP_VERSION-gd"

# dependencies used by the app (must be on a single line)
pkg_dependencies="$php_dependencies"

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
	[ $(find "$final_path" -type f | wc -l) -gt 0 ] && find "$final_path" -type f | xargs chmod 0644
	[ $(find "$final_path" -type d | wc -l) -gt 0 ] && find "$final_path" -type d | xargs chmod 0755
	[ $(find "$datadir" -type f | wc -l) -gt 0 ] && find "$datadir" -type f | xargs chmod 0644
	[ $(find "$datadir" -type d | wc -l) -gt 0 ] && find "$datadir" -type d | xargs chmod 0755
	chmod -R o-rwx "$final_path"
	chown -R $app:www-data "$final_path"
	chmod -R o-rwx "$datadir"
	chown -R $app:www-data "$datadir"
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
