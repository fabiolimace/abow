#!/bin/bash
#
# Usage:
#
#    abw-list
#    abw-list -c COLLECTION
#    abw-list -c COLLECTION -m "hash,name"
#


OPTSTRING="lc:m:"
source `dirname $0`/abw-common.sh

function list_fs {

    local COLLECTION="${1}";
    local METAFIELDS="${2}";
    
    declare -A meta;
    declare -A size;

    for i in `find "$DATADIR/$COLLECTION" -type f -name "meta.txt"`; do

        while read -r line; do
        
            key="${line%=*}"
            val="${line#*=}"
            
            for m in `echo "$METAFIELDS" | tr "," " "`; do
                if [[ "$key" == "$m" ]]; then
                    meta[$key]="$val";

                    if [[ ${#key} -gt ${size[$key]:=0} ]]; then
                        size[$key]="${#key}";
                    fi;
                    
                    if [[ ${#val} -gt ${size[$key]:=0} ]]; then
                        size[$key]="${#val}";
                    fi;
                fi;
            done;
            
        done < $i;
        
        if [[ ! ${headerprinted} ]]; then
            for m in `echo "$METAFIELDS" | tr "," " "`; do
                if [[ ${meta[$m]} ]]; then
                    length=${size[$m]:=0}
                    printf "%-${length}s\t" "${m^^}"
                fi;
            done;
            echo;
            headerprinted=1
        fi;
        
        for m in `echo "$METAFIELDS" | tr "," " "`; do
            if [[ ${meta[$m]} ]]; then
                length=${size[$m]:=0}
                printf "%-${length}s\t" "${meta[$m]}"
            fi;
        done;
        echo;
    done;
}

function list_db {

    local COLLECTION="${1}";
    local METAFIELDS="${2}";

    local DATABASE=`database $COLLECTION`
        
    # underlines for column names
    METAFIELDS=${METAFIELDS//,/_,}_
    
    sqlite3 -column -header "$DATABASE" "select $METAFIELDS from meta_;";
}

COLLECTION="${options["c"]:-default}";
METAFIELDS="${options["m"]:=uuid,collection,name,bytes,date}"

if [[ -d "$DATADIR/$COLLECTION" ]]; then
    list_fs "$COLLECTION" "$METAFIELDS";
elif [[ -f "$DATADIR/$COLLECTION.db" ]]; then
    list_db "$COLLECTION" "$METAFIELDS";
else
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

