#!/bin/bash
#
# Usage:
#
#    abw-grep REGEX
#    abw-grep -c COLLECTION REGEX
#    abw-grep -c COLLECTION -m REGEX
#    abw-grep -c COLLECTION -d REGEX
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

declare -A options;
OPTSTRING="gc:md"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

REGEX="${1}";
COLLECTION="${options["c"]:-default}"

if [[ ! -d "$DATADIR/$COLLECTION" ]]; then
    echo "abw-grep.sh: $COLLECTION: Collection not found" >> /dev/stderr;
    exit 1;
fi;

if [[ ${options["m"]} ]]; then
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/meta.txt
elif [[ ${options["d"]} ]]; then
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/data.tsv
else
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/text.txt
fi;


