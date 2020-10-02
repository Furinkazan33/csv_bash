#! /bin/bash
#############################################################
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Script to handle csv files like :
##
#ID;NAME;AGE;CITY
#1;Mathieu;35;Bordeaux
#2;Gertrude;102;Soulac
##
#############################################################
#TODO: Translate to English
#TODO: Seems like the save function is not working
#############################################################
# Example :
# . csvedit test.csv
# find
# find ID 1 | set AGE 55
#############################################################

#set -e
#set -o pipefail

[ "$0" = "$BASH_SOURCE" ] && echo "Usage : . $BASH_SOURCE file_name" && exit 1
[ -z $* ] && echo "Usage : . $BASH_SOURCE file_name" && return 1
[ ! -f $1 ] && echo "No such file: $1" && return 1


# File sorted by id
file=$1
    
# File structure definition
rows2=()

init_rows() {
    local def=$(head -n 1 "$file")
    local OLDIFS=$IFS

    IFS=";" && for r in $def; do
	rows2+=($r)
    done

    IFS=$OLDIFS
}
init_rows

_get_row_index() {
    for i in ${!rows2[@]}; do
	[ $1 == "${rows2[$i]}" ] && echo $(($i+1)) && return 0
    done
    echo -1 && return 1
}

file() {
    echo "$file"
}

rows() {
    head -n 1 "$file"
}

find() {
    [ ${#*} -ne 0 ] && [ ${#*} -ne 2 ] && echo "Usage: find field value" && return 1    
    [ ${#*} -eq 0 ] && tail -n +2 "$file" && return 0

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    tail -n +2 "$file" | awk -v row=$index -v value=$2 -F ";" '{ if($row==value) print $0 }'
}

find_one() {
    find $* | head -1
}

limit() {
    head -n $2 | tail -$(($2 - $1 + 1)) < "/dev/stdin"
}

get() { 
    [ ${#*} -ne 1 ] && echo "Usage: get field" && return 1

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    awk -v row=$index -F ";" '{ print $row }' < "/dev/stdin"
}


set() {
    [ ${#*} -ne 2 ] && echo "Usage: set field value" && return 1

    index=$(_get_row_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    OLDIFS=$IFS
    IFS=$'\n'

    awk -v row=$index -v value=$2 'BEGIN{FS=";"; OFS=FS} { $row=value; print $0 }' < "${3:-/dev/stdin}"

    IFS=$OLDIFS
}

_new_id(){
    local lastline=$(tail -n +2 "$file" | tail -1)
    local lastid=$(echo $lastline | get id)
    
    id=$((10#$lastid + 1))
    #id=$(printf "%010d" $id)
    
    echo $id
}

new() {
    echo $(_new_id)";"$1
}

_insert() { 
    [ ${#*} -ne 0 ] && echo "Usage: insert stdin" && return 1
    
    while read newline; do
	echo $newline | set id $(_new_id) >> "$file"
    done < "/dev/stdin"
}

# Insert or replace
save() {
    [ ${#*} -ne 0 ] && echo "Usage: save stdin" && return 1

    local OLDIFS=$IFS

    IFS=$'\n' && while read newline; do
        local id=$(echo $newline | get id)
        local oldline=$(find id $id)

        if [ -z $oldline ]; then
            echo $newline | _insert
        else
            sed "s/^$oldline$/$newline/" "$file" > "$file.tmp"
            mv "$file.tmp" "$file"
        fi
        echo $newline
	
    done < "/dev/stdin"

    IFS=$OLDIFS
}

delete() {
    [ ${#*} -ne 0 ] && echo "Usage: delete stdin" && return 1

    local rc=0

    while read line; do
	id=$(echo $line | get id)
	dbline=$(find id $id)

	if [ -z "$dbline" ]; then
	    rc=1
	else
	    sed "/^$dbline$/d" "$file" > "$file.tmp"
	    mv "$file.tmp" "$file"
	    rm -f "$file.tmp"
	    echo $line
	fi

    done < "/dev/stdin"
    
    return $rc
}

# TODO: after
row_add() {
    [ ${#*} -ne 1 ] && [ ${#*} -ne 2 ]  && echo "Usage: row_add new_row [after_row]" && return 1

    new_row=$1

    header=$(head -n 1 "$file")
    new_header=$header";"$new_row

    echo "$new_header" 
    echo "Confirmer ? (o/n)"
    read answer
    [ ! $answer == "o" ] && [ ! $answer == "O" ] && [ ! $answer == "oui" ] && [ ! $answer == "Oui" ] && [ ! $answer == "OUI" ] && echo "Abandon" && echo $header && return 1

    sed "s/^$header$/$new_header/" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"

    echo $new_header
}

row_delete() {
    [ ${#*} -ne 1 ] && echo "Usage: row_delete row" && return 1

    row=$1
    
    header=$(head -n 1 "$file")
    index=$(_get_row_index $row)
    [ $? -ne 0 ] && echo "Colonne inexistante !" && return 1

    [ $index -eq 1 ] && echo "Impossible de supprimer la cle primaire !" && return 1

    
    
}

function help() {
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
    echo -e "rows\t\tAffiche les entetes des colonnes"
    echo -e "row_add\t\tAjoute une colonne"
    echo -e "row_delete\tSupprime une colonne"
}

help