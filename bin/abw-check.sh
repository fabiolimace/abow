#!/bin/bash
#
# Usage:
#
#    abw-check
#    abw-check -c COLLECTION
#

OPTSTRING="kc:"
source `dirname $0`/abw-common.sh

function checksum {

    local ROAD="${1}"
    local META="$ROAD/meta.txt"
    local TEXT="$ROAD/text.txt"
    
    local HASH=`meta_value "$META" "hash"`
    
    if [ -z "$HASH" ];
    then
        echo "abw-check.sh: $META: hash not found" 1>&2;
        return;
    fi;
    
    echo -n "$HASH $TEXT" | sha1sum --check --status || echo "abw-check.sh: $TEXT: checksum failed" 1>&2;
}

function check_fs {
    for i in `find "$DATADIR/$COLLECTION" -type d -name "*-*-*-*-*"`; do
        checksum $i;
    done;
}

function check_db {
    echo "Not implemented for yet for SQLite database." # TODO
}

REGEX="${1}";
COLLECTION="${options["c"]:-default}"

if [[ -d "$DATADIR/$COLLECTION" ]]; then
    check_fs;
elif [[ -f "$DATADIR/$COLLECTION.db" ]]; then
    check_db;
else
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

