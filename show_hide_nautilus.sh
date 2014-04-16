#!/bin/bash
#
# Skrypt do ukrywania plików i katalogów, głównie przeznaczony dla nautilus-scripts lub nautilus-actions.
# Autor:    panjandrum <panjandrummail@gmail.com>
# Wersja:   1.0
# Data:     02.2010
# Licencja: GNU GPL v.3 oraz każda nowsza
#

# Sposób powiadamiania o błędach

WARN_PROGRAM="zenity --title=${0##*/} --warning --text" # okno gtk

warning() {
    ${WARN_PROGRAM} "$*"
}

if ! [ -e /usr/bin/zenity ]
then
	WARN_PROGRAM="echo -e"
fi

if [ $# == "0" ]
then
	warning "Nie podano żadnych plików ani katalogów."
	exit 1
fi

# Główna pętla

for (( i=1 ; $i<=$# ; i++ )) ;
do
	EXIT_STATUS=0
	FULL_NAME="${!i}"
	SHORT_NAME=`basename "$FULL_NAME"`
	DIR_NAME=`dirname "$FULL_NAME"`
	HIDDEN_FILE="$DIR_NAME/.hidden"

	if [ -a "$FULL_NAME" ]
	then
		if [ -f "$HIDDEN_FILE" ]
		then
			if [ -r "$HIDDEN_FILE" ]
			then
				HIDE_FILE="1"
				LINE_NR=0
				while read LINE ;
				do
					((LINE_NR++))
	 				if [ "$LINE" == "$SHORT_NAME" ]
					then
						HIDE_FILE="0"
						break
					fi
				done < "$HIDDEN_FILE"
				if [ $HIDE_FILE == "1" ]
				then
					echo "$SHORT_NAME" >> "$HIDDEN_FILE" 2> /dev/null
					EXIT_STATUS=$?
				else
					sed -i "$LINE_NR d" "$HIDDEN_FILE" 2> /dev/null
					EXIT_STATUS=$?
				fi
			else
				warning "Błąd w trakcie przetwarzania \"$SHORT_NAME\".\nBrak praw odczytu dla pliku .hidden."
			fi
		else
			echo "$SHORT_NAME" >> "$HIDDEN_FILE" 2> /dev/null
			EXIT_STATUS=$?
		fi
	else
		warning "Błąd w trakcie przetwarzania \"$SHORT_NAME\".\nTaki element nie istnieje."	

	fi
	if ! [ $EXIT_STATUS == 0 ]
	then
		warning "Błąd w trakcie przetwarzania \"$SHORT_NAME\".\nNie można zapisać do pliku .hidden."
	fi

done

# Odświerzanie katalogu w nautilusie, wymuszając Ctrl+R (wymaga pakietu xautomation)
if [ -e /usr/bin/xte ]
then
	xte "keydown Control_L"; xte "key r"; xte "keyup Control_L"
fi

exit 0


