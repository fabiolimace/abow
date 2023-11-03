#!/bin/bash
#
# Usage:
#
#    abow-show ID
#    abow-show -c COLLECTION ID
#    abow-show -c COLLECTION -m ID
#    abow-show -c COLLECTION -d ID
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

declare -A options;
OPTSTRING="sc:md"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

SUID="${1}";
COLLECTION="${options["c"]:-default}"

if [[ ! -d "$DATADIR/$COLLECTION" ]]; then
    echo "abow-show.sh: $COLLECTION: Directory not found" >> /dev/stderr;
    exit 1;
fi;

for i in `ls $DATADIR/$COLLECTION/$SUID/`; do

    if [[ ${options["m"]} ]]; then
        cat $DATADIR/$COLLECTION/$SUID/$i/meta.txt
    elif [[ ${options["d"]} ]]; then
        cat $DATADIR/$COLLECTION/$SUID/$i/data.tsv
    else
        cat $DATADIR/$COLLECTION/$SUID/$i/text.txt
    fi;
done;

