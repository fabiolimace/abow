#!/bin/bash
#
# Usage:
#
#    abw-grep REGEX
#    abw-grep -c COLLECTION REGEX
#
# Note: it it uses GLOB when the collection is a SQLite database.
#

OPTSTRING="gc:"
source `dirname $0`/abw-common.sh

function grep_fs {

    local COLLECTION="${1}"
    local REGEX="${2}"

    grep -E -r --color=auto "$REGEX" "$DATADIR/$COLLECTION"/*/*/*/text.txt
}

function glob_db {

    local COLLECTION="${1}"
    local REGEX="${2}"
    
    local DATABASE=`database $COLLECTION`
    
    sqlite3 -header "$DATABASE" "select * from text_ where content_ glob '$REGEX'";
}

REGEX="${1}";
COLLECTION="${options["c"]:-default}"

if [[ -z "$REGEX" ]]; then
    echo "abw-show.sh: REGEX required" 1>&2;
    exit 1;
fi;

if [[ -d "$DATADIR/$COLLECTION" ]]; then
    grep_fs "$COLLECTION" "$REGEX";
elif [[ -f "$DATADIR/$COLLECTION.db" ]]; then
    glob_db "$COLLECTION" "$REGEX";
else
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

