#
# Common variables & functions
#

# Package dependencies
PKG_DEPENDENCIES="php5-curl php5-gd"

# Check if directory/file already exists (path in argument)
myynh_check_path () {
	[ -z "$1" ] && ynh_die "No argument supplied"
	[ ! -e "$1" ] || ynh_die "$1 already exists"
}

# Create directory only if not already exists (path in argument)
myynh_create_dir () {
	[ -z "$1" ] && ynh_die "No argument supplied"
	[ -d "$1" ] || sudo mkdir -p "$1"
}

# Check if enough disk space available on backup storage
myynh_check_disk_space () {
	file_to_analyse=$1
	backup_size=$(sudo du --summarize "$1" | cut -f1)
	free_space=$(sudo df --output=avail "/home/yunohost.backup" | sed 1d)
	if [ $free_space -le $backup_size ]
	then
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
	sudo cp ../conf/nginx.conf "$nginx_conf"
	# To avoid a break by set -u, use a void substitution ${var:-}. If the variable is not set, it's simply set with an empty variable.
	# Substitute in a nginx config file only if the variable is not empty
	if test -n "${path_url:-}"; then
		ynh_replace_string "__PATH__" "$path_url" "$nginx_conf"
	fi
	if test -n "${final_path:-}"; then
		ynh_replace_string "__FINALPATH__" "$final_path" "$nginx_conf"
	fi
	if test -n "${app:-}"; then
		ynh_replace_string "__NAME__" "$app" "$nginx_conf"
	fi
	if test -n "${filesize:-}"; then
		ynh_replace_string "__FILESIZE__" "$filesize" "$nginx_conf"
	fi
	ynh_store_file_checksum "$nginx_conf"
	sudo systemctl reload nginx
}

# Create a dedicated php-fpm config
myynh_add_fpm_config () {
	ynh_backup_if_checksum_is_different "$phpfpm_conf" 1
	sudo cp ../conf/php-fpm.conf "$phpfpm_conf"
	postsize=${filesize%?}.1${filesize: -1}
	ynh_replace_string "__FINALPATH__" "$final_path" "$phpfpm_conf"
	ynh_replace_string "__NAME__" "$app" "$phpfpm_conf"
	ynh_replace_string "__FILESIZE__" "$filesize" "$phpfpm_conf"
	ynh_replace_string "__POSTSIZE__" "$postsize" "$phpfpm_conf"
	sudo chown root: "$phpfpm_conf"
	ynh_store_file_checksum "$phpfpm_conf"
	sudo systemctl reload php5-fpm
}

myynh_set_permissions () {
	[ $(sudo find "$final_path" -type f | wc -l) -gt 0 ] && sudo find "$final_path" -type f | xargs sudo chmod 0644
	[ $(sudo find "$final_path" -type d | wc -l) -gt 0 ] && sudo find "$final_path" -type d | xargs sudo chmod 0755
	[ $(sudo find "$data_path" -type f | wc -l) -gt 0 ] && sudo find "$data_path" -type f | xargs sudo chmod 0644
	[ $(sudo find "$data_path" -type d | wc -l) -gt 0 ] && sudo find "$data_path" -type d | xargs sudo chmod 0755
	sudo chown -R root:"$app" "$final_path"
	sudo chown -R "$app": "$final_path/private"
	sudo chown -R "$app": "$data_path"
	sudo chown root: "$data_path"
}
