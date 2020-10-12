#! /bin/bash
#############################################################
# csv_bash
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# User functions
#############################################################

file() {
    echo "$FILE"
}

headers() {
    echo ${HEADERS[@]}
}

find() {
    [ ${#*} -ne 0 ] && [ ${#*} -ne 2 ] && echo "Usage: find field value" && return 1    
    [ ${#*} -eq 0 ] && tail -n +2 "$FILE" && return 0

    index=$(_get_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    tail -n +2 "$FILE" | awk -v row=$index -v value=$2 -F "$SEPARATOR" '{ if($row==value) print $0 }'
}

find_one() {
    find $* | head -1
}

limit() {
    head -n $2 | tail -$(($2 - $1 + 1)) < "/dev/stdin"
}

get() { 
    [ ${#*} -ne 1 ] && { echo "Usage: get field"; return 1; }

    index=$(_get_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    awk -v row=$index -F "$SEPARATOR" '{ print $row }' < "/dev/stdin"
}

# Set can be done only on whole rows (ie, not after a get)
set() {
    [ ${#*} -ne 2 ] && { echo "Usage: set field value"; return 1; }

    index=$(_get_index "$1")
    [ $? -ne 0 ] && echo "Champs inconnu: $1" && return 1

    OLDIFS=$IFS
    IFS=$'\n'

    awk -v row=$index -v value=$2 'BEGIN{FS="'"$SEPARATOR"'"; OFS=FS} { $row=value; print $0 }' < "${3:-/dev/stdin}"

    IFS=$OLDIFS
}

new() {
    ([ $# -ne 1 ] || [ ! `_check_new_line $1` -eq 0 ]) && { 
        newline=$(headers | cut -d"$SEPARATOR" -f2-)
        echo "Usage: new \"$newline\""
        return 1
    }

    echo $(_new_id)"$SEPARATOR"$1
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

# Add a new column $1 at the end
# TODO: Before which existing column as $2
c_add() {
    [ ${#*} -ne 1 ] && [ ${#*} -ne 2 ] && echo "Usage: c_add <new_name>" && return 1

    new_name=$1

    headers | grep $new_name && echo "Existing header !" && return 1

    awk '{ if(NR==1) \
            printf "%s%s\n", $0, "'$SEPARATOR$new_name'"; \
        else \
            printf "%s%s\n", $0, "'$SEPARATOR'"; }' "$FILE" > "$FILE.tmp"
    
    mv "$FILE.tmp" "$FILE"

    HEADERS+=($new_name)

    echo $(head -n 1 "$FILE")
}

# TODO: Move a column before the specified one
c_move_before() {
    [ ${#*} -ne 2 ]  && echo "Usage: c_move_before <column_to_move> <before_this_column>" && return 1
    return 0
}

# Delete the given column
c_delete() {
    [ ${#*} -ne 1 ] && echo "Usage: c_delete <column_name>" && return 1

    column_name=$1
    
    header=$(head -n 1 "$FILE")
    index=$(_get_index $column_name)

    [ $? -ne 0 ] && echo "Colonne inexistante !" && return 1
    [ $index -eq 1 ] && echo "Impossible de supprimer la cle primaire !" && return 1

    awk -vkf=$index -vFS="$SEPARATOR" -vOFS="$SEPARATOR" '{ \
        for (i=kf; i<NF;i++){ \
            $i=$(i+1);
        }; \
        NF--; print \
    }' "$FILE" > "$FILE.tmp"

    mv "$FILE.tmp" "$FILE"

    HEADERS=( ${HEADERS[@]/$column_name} )

    echo $(head -n 1 "$FILE")
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
    echo -e "c_add\t\tAjoute une colonne"
    echo -e "c_delete\tSupprime une colonne"
    echo -e "c_move_before\tPas encore implémenté"
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
    echo -e "c_add\t\tAdd a column"
    echo -e "c_delete\tRemove a column"
    echo -e "c_move_before\tNot implemented yet"
}
