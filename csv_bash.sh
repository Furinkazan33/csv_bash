#! /bin/bash
#############################################################
# csv_bash
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Script to handle csv files with SEMI-COLON or COMMA separator
# The files must have a column ID which is unique
# See "help" command for more details
#############################################################

#############################################################
# Get parameters
#############################################################
FILE=$1
SEPARATOR=$2
[ -z "$SEPARATOR" ] && SEPARATOR=";"

#############################################################
# Importing functions
#############################################################
. ./lib/usages.sh
. ./lib/util.sh
. ./lib/user_functions.sh
. ./lib/init.sh

#############################################################
# Usages and parameters check
#############################################################
[ "$0" = "$BASH_SOURCE" ] && not_execute && exit 1
[ "$0" != "bash" ] && not_bash && return 1
[ $# -ne 1 ] && [ $# -ne 2 ] && usage && return 1
[ ! -f "$1" ] && echo "No such file: $1" && return 1

#############################################################
# Starting the environment
#############################################################
_init_message
_backup_file
_sort_file
_init_headers

help
