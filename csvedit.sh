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

headers() {
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
    local lastid=$(echo $lastline | get ID)
    
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
	echo $newline | set ID $(_new_id) >> "$file"
    done < "/dev/stdin"
}

# Insert or replace
save() {
    [ ${#*} -ne 0 ] && echo "Usage: save stdin" && return 1

    local OLDIFS=$IFS

    IFS=$'\n' && while read newline; do
        local id=$(echo $newline | get ID)
        local oldline=$(find ID $id)

        if [ -z $oldline ]; then
            echo $newline | _insert
        else
            sed s/^${oldline}$/${newline}/ $file > $file.tmp
            mv $file.tmp $file
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
	    sed "/^$dbline$/d" "$file" > "$file.tmp"
	    mv "$file.tmp" "$file"
	    rm -f "$file.tmp"
	    echo $line
	fi

    done < "/dev/stdin"
    
    return $rc
}

# TODO: after
column_add() {
    [ ${#*} -ne 1 ] && [ ${#*} -ne 2 ]  && echo "Usage: column_add new_row [after_row]" && return 1

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

column_delete() {
    [ ${#*} -ne 1 ] && echo "Usage: column_delete row" && return 1

    row=$1
    
    header=$(head -n 1 "$file")
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
    echo -e "column_add\t\tAjoute une colonne"
    echo -e "column_delete\tSupprime une colonne"
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
    echo -e "column_add\tAdd a column"
    echo -e "column_delete\tRemove a column"
}

help