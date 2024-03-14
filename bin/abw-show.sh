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

UUID="${1}";
COLLECTION="${options["c"]:-default}"
ROAD=`directory "$COLLECTION" "$UUID"`;

if [[ -z "$UUID" ]]; then
    echo "abw-show.sh: UUID required" 1>&2;
    exit 1;
fi;

if [[ ! -d "$DATADIR/$COLLECTION" ]]; then
    echo "abw-show.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

if [[ ! -d "$ROAD" ]]; then
    echo "abw-show.sh: $UUID: UUID not found" 1>&2;
    exit 1;
fi;

if [[ ${options["m"]} ]]; then
    cat "$ROAD/meta.txt"
elif [[ ${options["d"]} ]]; then
    cat "$ROAD/data.tsv"
else
    cat "$ROAD/text.txt"
fi;

