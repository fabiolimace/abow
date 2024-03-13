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

REGEX="${1}";
COLLECTION="${options["c"]:-default}"

UUID=`pad`; # wildcard-padded UUID
ROAD=`road "$COLLECTION" "$UUID"`;

if [[ ! -d "$DATADIR/$COLLECTION" ]]; then
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

for i in `find "$DATADIR/$COLLECTION" -type d -name "*-*-*-*-*"`; do
    checksum $i;
done;

