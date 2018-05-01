#
# Common variables & functions
#

# Package dependencies
PKG_DEPENDENCIES="php5-curl php5-gd"
if [ "$(lsb_release --codename --short)" != "jessie" ]; then
	PKG_DEPENDENCIES="$PKG_DEPENDENCIES php-zip"
fi

# Check if directory/file already exists (path in argument)
myynh_check_path () {
	[ -z "$1" ] && ynh_die "No argument supplied"
	[ ! -e "$1" ] || ynh_die "$1 already exists"
}

# Create directory only if not already exists (path in argument)
myynh_create_dir () {
	[ -z "$1" ] && ynh_die "No argument supplied"
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
		ynh_die "Space needed: $(HUMAN_SIZE $backup_size)"
	fi
}

# Clean & copy files needed to final folder
myynh_clean_source () {
	find "$TMPDIR" -type f -name ".htaccess" | xargs rm
	[ -e "$TMPDIR/.gitignore" ] && rm -r "$TMPDIR/.gitignore"
}

# Create a dedicated nginx config
myynh_add_nginx_config () {
	ynh_backup_if_checksum_is_different "$nginx_conf" 1
	cp ../conf/nginx.conf "$nginx_conf"
	# To avoid a break by set -u, use a void substitution ${var:-}. If the variable is not set, it's simply set with an empty variable.
	# Substitute in a nginx config file only if the variable is not empty
	[ -n "${path_url:-}" ] && ynh_replace_string "__PATH__" "$path_url" "$nginx_conf"
	if [ "${path_url:-}" != "/" ]; then
		ynh_replace_string "^#sub_path_only" "" "$nginx_conf"
	fi
	[ -n "${final_path:-}" ] && ynh_replace_string "__FINALPATH__" "$final_path" "$nginx_conf"
	[ -n "${app:-}" ] && ynh_replace_string "__NAME__" "$app" "$nginx_conf"
	[ -n "${filesize:-}" ] && ynh_replace_string "__FILESIZE__" "$filesize" "$nginx_conf"
	ynh_store_file_checksum "$nginx_conf"
	systemctl reload nginx
}
# Create a dedicated php-fpm config
myynh_add_fpm_config () {
	ynh_backup_if_checksum_is_different "$phpfpm_conf" 1
	cp ../conf/php-fpm.conf "$phpfpm_conf"
	postsize=${filesize%?}.1${filesize: -1}
	ynh_replace_string "__FINALPATH__" "$final_path" "$phpfpm_conf"
	ynh_replace_string "__NAME__" "$app" "$phpfpm_conf"
	ynh_replace_string "__FILESIZE__" "$filesize" "$phpfpm_conf"
	ynh_replace_string "__POSTSIZE__" "$postsize" "$phpfpm_conf"
	chown root: "$phpfpm_conf"
	ynh_store_file_checksum "$phpfpm_conf"
	systemctl reload php5-fpm
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

#=================================================
# FUTURE YUNOHOST HELPERS - TO BE REMOVED LATER
#=================================================

# Delete a file checksum from the app settings
#
# $app should be defined when calling this helper
#
# usage: ynh_remove_file_checksum file
# | arg: file - The file for which the checksum will be deleted
ynh_delete_file_checksum () {
	local checksum_setting_name=checksum_${1//[\/ ]/_}	# Replace all '/' and ' ' by '_'
	ynh_app_setting_delete $app $checksum_setting_name
}
