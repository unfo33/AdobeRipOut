#!/bin/bash
#
# this script attempts to remove all traces of the adobe creative cloud -after- running
# the adobe provided creative cloud uninstallation script. 

# -- START CONFIGURTATION --
APPLICATIONS_PATH=( "/Applications" "/Applications/Utilities" )
BOOTCACHE_PATH="/private/var/db/BootCaches"
USER_DIRECTORIES=("/var/root" "$(ls -d -1 /Users/*)" "/" )
OUTPUT_LOG_FILE="/var/log/adobe.cleanup.$(date +%s).log"

LIB_SEARCH_DIRS[0]="Library/Application Support"
LIB_SEARCH_DIRS[1]="Library/Caches"
LIB_SEARCH_DIRS[2]="Library/Preferences"
LIB_SEARCH_DIRS[3]="Library/Logs"
LIB_SEARCH_DIRS[4]="Library/Saved Application State"
LIB_SEARCH_DIRS[5]="Library/Documents"
# -- END CONFIGURATION --

# given the absolute path to a directory, checks for adobe
# references in $LIB_SEARCH_DIRS and removes any references if they exist.
# @param $1 - homedir (abs path)
function scan_for_adobe_leftovers() {
	#verify $1 (homedir) was actually provided to the function and that it exists
	if [ -z $1 ] & [ -d $1 ]; then
			local homedir=$1
			for lib_folder in "${LIB_SEARCH_DIRS[@]}"; do
				find "${homedir}/${lib_folder}" -iname "*adobe*" 2> /dev/null | while read match; do
					echo "---- ---- REMOVING ${match}..." >> $OUTPUT_LOG_FILE
					if [ -f "$match" ]; then
						rm "$match"
					elif [ -d "$match" ]; then
						rm -r "$match"
					fi
				done
			done

			if [ -d "${homedir}/.adobe" ]; then
				rm -rf "${homedir}/.adobe"
			fi
	else
		echo "++++ ERROR: No argument for scan_for_adobe_leftovers() or directory doesn't exist!" >> $OUTPUT_LOG_FILE
	fi
}

# verify no adobe processes are running - if they are, kill them
# force killing is find in this situation because we're removing
# the application and all associated files anyway. 
echo "DEBUG: SCANNING FOR RUNNING ADOBE PROCESSES" >> $OUTPUT_LOG_FILE
for pid in $(ps ax | grep -i adobe | grep -v "$0" | awk '{ print $1 }'); do
	echo "---- KILLING PROCESS: #${pid}..." >> $OUTPUT_LOG_FILE
	kill -9 $pid
done

# loop through the APPLICATIONS_PATH folder and remove any 
# applications belonging to Adobe
for app_path in ${APPLICATIONS_PATH[@]}; do
	for app in ${app_path}/*; do
		if [[ "$app" =~ (adobe|Adobe)+ ]]; then
				echo "REMOVING APPLICATION: ${app}..." >> $OUTPUT_LOG_FILE
				rm -rf "$app"
		fi
	done
done

echo "DEBUG: REMOVE ALL BOOTCACHE_PATH REFERENCES" >> $OUTPUT_LOG_FILE
find "$BOOTCACHE_PATH" -iname "*adobe*" 2> /dev/null | while read match; do
	if [ -f "$match" ]; then
		echo "---- REMOVING $match" >> $OUTPUT_LOG_FILE
		rm "$match"
	elif [ -d "$match" ]; then
		echo "---- REMOVING $match" >> $OUTPUT_LOG_FILE
		rm -rf "$match"
	fi
done

# loop through all users and scan their homedir for reminants of Adobe
echo "DEBUG: SCANNING USER HOMEDIRS FOR LINGERING REFERENCES" >> $OUTPUT_LOG_FILE
for homedir in ${USER_DIRECTORIES[@]}; do
	if [ -d $homedir ]; then
		echo "---- SCANNING ${homedir}..." >> $OUTPUT_LOG_FILE
		scan_for_adobe_leftovers "$homedir"
	fi
done

cat $OUTPUT_LOG_FILE
