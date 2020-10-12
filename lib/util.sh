#! /bin/bash
#############################################################
# csv_bash
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Utility functions
#############################################################

# Returns the index + 1 of the column
_get_index() {
    [ $# -ne 1 ] && { echo "Usage: _get_index <name>"; return 1; }

    for i in ${!HEADERS[@]}; do
	    [ "$1" == "${HEADERS[$i]}" ] && echo $(($i+1)) && return 0
    done
    echo -1 && return 1
}

_new_id(){
    local lastid=$(tail -1 "$FILE" | get ID)
    
    echo $((10#$lastid + 1))
}

# Count the number of columns from a row (header or data)
_count_columns() {
    OLDIFS=$IFS
    IFS="$SEPARATOR" && echo $* | wc -w
    IFS=$OLDIFS
}

# Check if the new line as the required number of columns
_check_new_line() {
    local row=$*
    local c_col=$(_count_columns $row)
    local c_head=$(_count_columns `headers`)

    [ $c_col -eq $(($c_head - 1)) ] && { echo 0; return 0; }
    echo 1; return 1;
}

# Insert new lines read from stdin at the end of the file
# with new IDs
_insert() { 
    [ ${#*} -ne 0 ] && echo "Usage: input | _insert" && return 1
    
    while read newline; do
	    echo $newline | set ID $(_new_id) >> "$FILE"
    done < "/dev/stdin"
}

# Ask for confirmation of $*
_confirm() {
    echo "$*"
    echo "Confirm ? (y/n)"
    read answer
    confirms="y Y yes YES Yes"
    
    local OLDIFS=$IFS
    IFS=" " && for c in $confirms; do
        [ "$answer" == "$c" ] && return 0
    done
    IFS=$OLDIFS

    return 1
}