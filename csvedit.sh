#! /bin/bash
#############################################################
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Script to handle csv files
#############################################################
# Example file :
# ID;NAME;AGE;CITY
# 1;Mathieu;35;Bordeaux
# 2;Gertrude;102;Soulac
#
# Test commands :
# . csvedit test.csv
# find
# find ID 1 | set AGE 55
#############################################################

#set -e
#set -o pipefail

not_bash() {
    echo "Your Shell is $0"
    echo "This is a bash source file"
}

usage() {
    echo "Usage : . csvedit.sh file_name"
}

not_execute() {
    echo "This file is intended to be sourced not executed !"
    usage
}

[ "$0" = "$BASH_SOURCE" ] && not_execute && exit 1
[ "$0" != "bash" ] && not_bash && return 1
[ $# -ne 1 ] && usage && return 1
[ ! -f "$1" ] && echo "No such file: $1" && return 1




# Sort file by ID
_sort_file() {
    local def="$(head -n 1 "$FILE")"
    local n=$(wc -l "$FILE" | cut -d" " -f1)
    local sorted_data="$(tail -n $(($n - 1)) $FILE | sort -n)"

    echo "$def" > $FILE
    echo "$sorted_data" >> $FILE
}

_init() {
    # Creating backup
    folder="./.bak"
    suffix=`date +%s`
    mkdir $folder 2> /dev/null
    cp $FILE $folder/$FILE.$suffix && {
        echo "Creating backup file $folder/$FILE.$suffix OK"
    } || { 
        echo "Impossible to create backup file - enter to exit"
        read
        exit 1
    }

    # Sorting file on IDs
    _sort_file

    # Initiaze HEADERS
    HEADERS=()
    local def=$(head -n 1 "$FILE")
    local OLDIFS=$IFS

    IFS=";" && for r in $def; do
	    HEADERS+=($r)
    done

    IFS=$OLDIFS
}

_get_row_index() {
    for i in ${!HEADERS[@]}; do
	    [ "$1" == "${HEADERS[$i]}" ] && echo $(($i+1)) && return 0
    done
    echo -1 && return 1
}

file() {
    echo "$FILE"
}

headers() {
    echo ${HEADERS[@]}
}

find() {
    [ ${#*} -ne 0 ] && [ ${#*} -ne 2 ] && echo "Usage: find field value" && return 1    
    [ ${#*} -eq 0 ] && tail -n +2 "$FILE" && return 0

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    tail -n +2 "$FILE" | awk -v row=$index -v value=$2 -F ";" '{ if($row==value) print $0 }'
}

find_one() {
    find $* | head -1
}

limit() {
    head -n $2 | tail -$(($2 - $1 + 1)) < "/dev/stdin"
}

get() { 
    [ ${#*} -ne 1 ] && { echo "Usage: get field"; return 1; }

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    awk -v row=$index -F ";" '{ print $row }' < "/dev/stdin"
}


# Set can be done only on whole rows (ie, not after a get)
set() {
    [ ${#*} -ne 2 ] && { echo "Usage: set field value"; return 1; }

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    OLDIFS=$IFS
    IFS=$'\n'

    awk -v row=$index -v value=$2 'BEGIN{FS=";"; OFS=FS} { $row=value; print $0 }' < "${3:-/dev/stdin}"

    IFS=$OLDIFS
}

_new_id(){
    local lastline=$(tail -n +2 "$FILE" | tail -1)
    local lastid=$(echo $lastline | get ID)
    
    id=$((10#$lastid + 1))
    #id=$(printf "%010d" $id)
    
    echo $id
}

_count_columns() {
    OLDIFS=$IFS
    IFS=";" && echo $* | wc -w
    IFS=$OLDIFS
}

_check_new_line() {
    local row=$*
    local c_col=$(_count_columns $row)
    local c_head=$(_count_columns `headers`)

    [ $c_col -eq $(($c_head - 1)) ] && { echo 0; return 0; }
    echo 1; return 1;
}

new() {
    ([ $# -ne 1 ] || [ ! `_check_new_line $1` -eq 0 ]) && { 
        newline=$(headers | cut -d";" -f2-)
        echo "Usage: new \"$newline\""
        return 1
    }

    echo $(_new_id)";"$1
}

_insert() { 
    [ ${#*} -ne 0 ] && echo "Usage: insert stdin" && return 1
    
    while read newline; do
	echo $newline | set ID $(_new_id) >> "$FILE"
    done < "/dev/stdin"
}

# Insert or replace
# Save can be done only on whole rows (ie, not after a get)
save() {
    [ ${#*} -ne 0 ] && echo "Usage: save stdin" && return 1

    local OLDIFS=$IFS

    IFS=$'\n' && while read newline; do
        local id=$(echo $newline | get ID)
        local oldline=$(find ID $id)

        if [ -z "$oldline" ]; then
            echo $newline | _insert
        else
            sed s/^${oldline}$/${newline}/ $FILE > $FILE.tmp
            mv $FILE.tmp $FILE
        fi
        echo $newline
	
    done < "/dev/stdin"

    IFS=$OLDIFS
}

delete() {
    [ ${#*} -ne 0 ] && echo "Usage: delete stdin" && return 1

    local rc=0

    while read line; do
	id=$(echo $line | get ID)
	dbline=$(find ID $id)

	if [ -z "$dbline" ]; then
	    rc=1
	else
	    sed "/^$dbline$/d" "$FILE" > "$FILE.tmp"
	    mv "$FILE.tmp" "$FILE"
	    rm -f "$FILE.tmp"
	    echo $line
	fi

    done < "/dev/stdin"
    
    return $rc
}

_confirm() {
    echo "Confirm ? (y/n)"
    read answer
    confirms="y Y yes YES Yes"
    
    local OLDIFS=$IFS
    IFS=" " && for c in $confirms; do
        echo $c
        [ "$answer" == "$c" ] && return 0
    done
    IFS=$OLDIFS

    return 1
}

# TODO: after
header_add() {
    [ ${#*} -ne 1 ] && [ ${#*} -ne 2 ]  && echo "Usage: header_add new_row [after_row]" && return 1

    new_row=$1

    header=$(head -n 1 "$FILE")
    new_header=$header";"$new_row

    echo "$new_header"
    _confirm || { echo "OK => $header"; return 1; }

    sed "s/^$header$/$new_header/" "$FILE" > "$FILE.tmp"
    mv "$FILE.tmp" "$FILE"

    echo "OK => $new_header"
}

header_delete() {
    [ ${#*} -ne 1 ] && echo "Usage: header_delete row" && return 1

    row=$1
    
    header=$(head -n 1 "$FILE")
    index=$(_get_row_index $row)
    [ $? -ne 0 ] && echo "Colonne inexistante !" && return 1

    [ $index -eq 1 ] && echo "Impossible de supprimer la cle primaire !" && return 1
}

function help_fr() {
    echo "Liste des commandes :"
    echo -e "help\t\tAffiche l'aide"
    echo -e "file\t\tAffiche le fichier de travail"
    echo -e "find\t\tRecherche par valeur d'une colonne"
    echo -e "find_one\tIdem recherche mais ne renvoi que la premiere ligne"
    echo -e "limit\t\tLimite le nombre des resultats"
    echo -e "get\t\tRetourne la valeur du champ des ligness"
    echo -e "set\t\tModifie la valeur du champs dans les lignes"
    echo -e "new\t\tCreer une nouvelle ligne"
    echo -e "save\t\tEnregistre les lignes dans le fichier de travail"
    echo -e "delete\t\tSupprime les lignes"
    echo -e "headers\t\tAffiche les entetes des colonnes"
    echo -e "header_add\t\tAjoute une colonne"
    echo -e "header_delete\tSupprime une colonne"
}

function help() {
    echo "Commands list :"
    echo -e "help\t\tPrint this help"
    echo -e "file\t\tPrint working file name"
    echo -e "find\t\tFind rows by column value"
    echo -e "find_one\tSame as above, returns only the first occurence found"
    echo -e "limit\t\tLimits the number of results"
    echo -e "get\t\tGet the values of the selected column"
    echo -e "set\t\tSet the values of the selected columns"
    echo -e "new\t\tCreate a new line"
    echo -e "save\t\tSave the lines in the working file"
    echo -e "delete\t\tDelete the lines"
    echo -e "headers\t\tPrint the headers names"
    echo -e "header_add\tAdd a column"
    echo -e "header_delete\tRemove a column"
}



FILE=$1
_init
help

