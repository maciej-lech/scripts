#!/bin/bash
#############################################################################################
#
# Skrypt dla nautilus-scripts lub nautilus-actions do rozpakowywania akrchiwów na pomocą unp
#
# Autor:    panjandrum <panjandrummail@gmail.com>
# Wersja:   1.0
# Data:     02.2010
# Licensja: GNU GPL3 lub każda nowsza
#
#############################################################################################

QUIET=1

WINDOW_TYPE="warning"
WARN_PROGRAM="zenity --title="Rozpakowywanie" --$WINDOW_TYPE --text" # okno gtk

warning() {
    ${WARN_PROGRAM} "$*"
}

if ! [ -e /usr/bin/unp ]
then
	warning "Program unp nie jest zainstalowany."
	exit 1
fi


for (( i=1 ; $i<=$# ; i++ )) ;
do
	EXIT_STATUS=0
 	FULL_NAME="${!i}"
	SHORT_NAME=`basename "$FULL_NAME"`
	DIR_NAME=`dirname "$FULL_NAME"`

	if [ -d "$FULL_NAME" ]
	then
		warning "\"$SHORT_NAME\" jest katalogiem."
		continue
	fi

	if [ -r "$FULL_NAME" ]
	then
		unp "$FULL_NAME" >/dev/null
		EXIT_STATUS=$?
	else
		warning "Plik \"$SHORT_NAME\" nie istnieje, lub nie można z niego czytać."
		continue
	fi

	if ! [ $EXIT_STATUS == 0 ]
	then
		warning "$EXIT_STATUS\nBłąd w trakcie rozpakowywania pliku \"$SHORT_NAME\".\nNiepoprawne archiwum, lub brak miejsca na dysku."
		continue
	fi

	if [ $QUIET == 0 ]
	then
		WINDOW_TYPE="info"
		warning "Rozpakowano archiwum \"$SHORT_NAME\"."
		WINDOW_TYPE="warning"
	fi


	# Dodatkowe czynnośći po rozpakowaniu

	if [ -e "$DIR_NAME/Napisy24.pl.url" ]
	then
		rm -f "$DIR_NAME/Napisy24.pl.url"
	fi

	if [ -e "$DIR_NAME/Snapik.com.url" ]
	then
		rm -f "$DIR_NAME/Snapik.com.url"
	fi

done

exit 0

