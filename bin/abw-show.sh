#!/bin/bash
#
# Usage:
#
#    abw-show UUID
#    abw-show -c COLLECTION UUID
#    abw-show -c COLLECTION -m UUID
#    abw-show -c COLLECTION -d UUID
#

OPTSTRING="sc:md"
source `dirname $0`/abw-common.sh

function show_fs {

    local COLLECTION="${1}"
    local UUID="${2}"

    DIRECTORY=`directory "$COLLECTION" "$UUID"`;

    if [[ ! -d "$DIRECTORY" ]]; then
        return;
    fi;

    if [[ ${options["m"]} ]]; then
        cat "$DIRECTORY/meta.txt"
    elif [[ ${options["d"]} ]]; then
        cat "$DIRECTORY/data.txt"
    else
        cat "$DIRECTORY/text.txt"
    fi;
}

# TODO
function show_db {

    local COLLECTION="${1}"
    local UUID="${2}"

    local DATABASE=`database $COLLECTION`
    
    if [[ ${options["m"]} ]]; then
        sqlite3 -column -header "$DATABASE" "select * from meta_ where uuid_ = '$UUID'";
    elif [[ ${options["d"]} ]]; then
        sqlite3 -column -header "$DATABASE" "select * from data_ where uuid_ = '$UUID'";
    else
        sqlite3 -header "$DATABASE" "select * from text_ where uuid_ = '$UUID'";
    fi;
}

UUID="${1}";
COLLECTION="${options["c"]:-default}"

if [[ -z "$UUID" ]]; then
    echo "abw-show.sh: UUID required" 1>&2;
    exit 1;
fi;

if [[ -d "$DATADIR/$COLLECTION" ]]; then
    show_fs "$COLLECTION" "$UUID";
elif [[ -f "$DATADIR/$COLLECTION.db" ]]; then
    show_db "$COLLECTION" "$UUID";
else
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

