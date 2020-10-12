#! /bin/bash
#############################################################
# csv_bash
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Init functions
#############################################################

# Init message display
_init_message() {
    echo "###########################################"
    echo "#          Welcome to csv_bash !          #"
    echo "###########################################"
    echo 
    echo "Your file separator is \"$SEPARATOR\""
    echo
}

# Create backup
_backup_file() {
    folder="./.bak"
    suffix=`date +%s`
    mkdir $folder 2> /dev/null
    cp $FILE $folder/$FILE.$suffix && {
        echo "Creating backup file $folder/$FILE.$suffix"
        echo "Done !"
    } || { 
        echo "Impossible to create backup file - enter to exit"
        read
        exit 1
    }
}

# Sort file by ID
_sort_file() {
    local def="$(head -n 1 "$FILE")"
    local n=$(wc -l "$FILE" | cut -d" " -f1)
    local sorted_data="$(tail -n $(($n - 1)) $FILE | sort -n)"

    echo "Sorting your file on Ids ..."
    echo "$def" > $FILE
    echo "$sorted_data" >> $FILE
    echo "Done !"
    echo
}

# Initialize HEADERS from file
_init_headers() {
    HEADERS=()
    local def=$(head -n 1 "$FILE")
    local OLDIFS=$IFS

    IFS="$SEPARATOR" && for r in $def; do
	    HEADERS+=($r)
    done

    IFS=$OLDIFS
}
