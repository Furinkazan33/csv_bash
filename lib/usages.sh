#! /bin/bash
#############################################################
# csv_bash
# Author : Mathieu Vidalies https://github.com/Furinkazan33
#############################################################
# Usages functions
#############################################################

not_bash() {
    echo "Your Shell is $0"
    echo "This is a bash source file"
}

usage() {
    echo "Usage : . csv_bash.sh <file_name> [separator, default=\";\"]"
}

not_execute() {
    echo "This file is intended to be sourced not executed !"
    usage
}
