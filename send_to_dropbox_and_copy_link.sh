#!/bin/bash
#
#		Dropbox CF-GU 0.2 - copy file to pub folder and get url
#
#       Copyright 2009, 2010 panjandrum <panjandrummail@gmail.com>
#     
#		Depends: zenity (show info), xsel (copy link to clipboard)
#  
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#

# Dropbox Public directory
DROPBOX_PUBLIC_PATH="$HOME/Dropbox/Public"

# Program who shows info
INFO_PROG1="echo -e"
INFO_PROG2="zenity --title=${0##*/} --warning --text"
USAGE="Usage: ${0##*/} file"

error_msg() {
	if [ $# != "0" ]
	then
		${INFO_PROG1} "$*"
		${INFO_PROG2} "$*"
	fi
	exit 1
}

if ! [ -e "$(which zenity)" ]
then
	$INFO_PROG1 "Zenity not instaled!"
	exit 1
fi


if ! [ -x "$(which xsel)" ]
then
	error_msg "Xsel not instaled!"
fi

if [ $# == "0" ]
then
	error_msg "$USAGE"
fi

if [ -r "$1" ]
then

	if [ -z "$(pidof dropbox)" ] 
	then
		error_msg "Dropbox isn't running!"
	else
		cp "$1" "$DROPBOX_PUBLIC_PATH" &
		PUB_FILE=`echo "$DROPBOX_PUBLIC_PATH/${1##*/}"`
		sleep 1
		LINK=`dropbox puburl "$PUB_FILE"`
		echo $LINK | xsel -i -b
		$INFO_PROG1 "${1##*/}:\n$LINK"
	fi
else
	error_msg "Not able to read a file: $1"
fi

exit 0


