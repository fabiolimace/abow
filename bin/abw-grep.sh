#!/bin/bash
#
# Usage:
#
#    abw-grep REGEX
#    abw-grep -c COLLECTION REGEX
#    abw-grep -c COLLECTION -m REGEX
#    abw-grep -c COLLECTION -d REGEX
#

OPTSTRING="gc:md"
source `dirname $0`/abw-common.sh

REGEX="${1}";
COLLECTION="${options["c"]:-default}"

if [[ ! -d "$DATADIR/$COLLECTION" ]]; then
    echo "abw-grep.sh: $COLLECTION: Collection not found" 1>&2;
    exit 1;
fi;

if [[ ${options["m"]} ]]; then
    grep -E -r --color=auto "$REGEX" "$DATADIR/$COLLECTION"/*/*/*/meta.txt
elif [[ ${options["d"]} ]]; then
    grep -E -r --color=auto "$REGEX" "$DATADIR/$COLLECTION"/*/*/*/data.tsv
else
    grep -E -r --color=auto "$REGEX" "$DATADIR/$COLLECTION"/*/*/*/text.txt
fi;

