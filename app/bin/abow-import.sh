#!/bin/bash
#
# Usage:
#
#    abow-import INPUT_FILE [FILE...]
#    abow-import -r DIRECTORY [DIRECTORY...]
#

BASEDIR=`dirname $0`
DATABASE="$BASEDIR/../database"

function import_file {

    local INPUT_FILE=${1}
    
    if [[ ! -f "$INPUT_FILE" ]];
    then
        echo "abow-import.sh: $INPUT_FILE: File not found" > /dev/stderr;
        exit 1;
    fi
    
    local UUID=` uuidgen --md5 --namespace @url --name "$INPUT_FILE"`
    local SUID=`echo $UUID | cut -d- -f1`
    local ITEM=$DATABASE/$SUID/$UUID;
    local TEXT=$ITEM/text.txt
    local META=$ITEM/meta.txt
    local DATA=$ITEM/data.tsv
    
    if [[ -d $ITEM ]];
    then
        echo "abow-import.sh: $INPUT_FILE: Already imported" > /dev/stderr;
        exit 1;
    fi;
    
    mkdir --parents $ITEM;
    
    cp $INPUT_FILE $TEXT
    
    echo "uuid=$UUID" >> $META
    echo "name=`basename $INPUT_FILE`" >> $META
    echo "path=`dirname $INPUT_FILE`" >> $META
    echo "hash=`md5sum $INPUT_FILE | cut -c-32`" >> $META
    echo "date=`date '+%F %T'`" >> $META
    echo "mime=`file -bi $INPUT_FILE`" >> $META
    echo "size=`wc -c $INPUT_FILE | cut -d" " -f1`" >> $META
   
    $BASEDIR/abow-compute.sh $TEXT $DATA
}

function parse_args {

    args=${1}
    args=${args//--recursive/-r} # TODO
    args=${args//--help/-h}      # TODO

    shopt -s extglob
    args=${args//--+([a-zA-Z0-9-])/-?}

    declare -A options;
    OPTSTRING="rh"

    while getopts "$OPTSTRING" name $args; do
          if [[ ${OPTARG} ]]; then
            options[${name}]=${OPTARG};
          else
            options[${name}]=${name};
          fi
    done;
    shift $(( ${OPTIND} - 1 ));
    
    while(($#)) ; do
        import_file $1
        shift
    done;
}

parse_args $@;

