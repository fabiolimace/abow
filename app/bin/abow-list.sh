#!/bin/bash
#
# Usage:
#
#    abow --list
#    abow -c COLLECTION
#    abow -c COLLECTION -m "hash,name"
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

declare -A options;
OPTSTRING="lc:m:"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

COLLECTION="${options["c"]}"
METAFIELDS="${options["m"]:=suid,collection,name,size,date}"

declare -A meta;
declare -A size;

for subdir in `find "$DATADIR/" -mindepth 1 -maxdepth 1 -type d | sort `; do

    test "`basename $subdir`" == "${COLLECTION:-`basename $subdir`}" || continue;

    for i in `find "$subdir" -type f -name "meta.txt"`; do

        while read -r line; do
        
            key="${line%=*}"
            val="${line#*=}"
            
            for m in `echo "$METAFIELDS" | tr "," " "`; do
                if [[ "$key" == "$m" ]]; then
                    meta["$key"]="$val";

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

done;

