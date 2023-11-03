#!/bin/bash
#
# Usage:
#
#    abow-find REGEX
#    abow-find -c COLLECTION REGEX
#    abow-find -c COLLECTION -m REGEX
#    abow-find -c COLLECTION -d REGEX
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

declare -A options;
OPTSTRING="fc:md"

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
    echo "abow-find.sh: $COLLECTION: Collection not found" >> /dev/stderr;
    exit 1;
fi;

if [[ ${options["m"]} ]]; then
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/meta.txt
elif [[ ${options["d"]} ]]; then
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/data.tsv
else
    grep -E -r --color=auto "$REGEX" $DATADIR/$COLLECTION/*/*/text.txt
fi;


