#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="php-zip php-curl php-gd"

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

# Check if enough disk space available on backup storage
myynh_check_disk_space () {
	file_to_analyse=$1
	backup_size=$(du --summarize "$1" | cut -f1)
	free_space=$(df --output=avail "/home/yunohost.backup" | sed 1d)
	if [ $free_space -le $backup_size ]; then
		WARNING echo "Not enough backup disk space for: $1"
		WARNING echo "Space available: $(HUMAN_SIZE $free_space)"
		ynh_die --message="Space needed: $(HUMAN_SIZE $backup_size)"
	fi
}

# Clean & copy files needed to final folder
myynh_clean_source () {
	find "$tmpdir" -type f -name ".htaccess" | xargs rm
	[ -e "$tmpdir/.gitignore" ] && rm -r "$tmpdir/.gitignore"
}

myynh_set_permissions () {
	[ $(find "$final_path" -type f | wc -l) -gt 0 ] && find "$final_path" -type f | xargs chmod 0644
	[ $(find "$final_path" -type d | wc -l) -gt 0 ] && find "$final_path" -type d | xargs chmod 0755
	[ $(find "$data_path" -type f | wc -l) -gt 0 ] && find "$data_path" -type f | xargs chmod 0644
	[ $(find "$data_path" -type d | wc -l) -gt 0 ] && find "$data_path" -type d | xargs chmod 0755
	chown -R root:"$app" "$final_path"
	chown -R "$app": "$final_path/private"
	chown -R "$app": "$data_path"
	chown root: "$data_path"
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
