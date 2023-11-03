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
        return;
    fi;
    
    local UUID=` uuidgen --md5 --namespace @url --name "$INPUT_FILE"`
    local SUID=`echo $UUID | cut -d- -f1`
    local ITEM=$DATABASE/$SUID/$UUID;
    local TEXT=$ITEM/text.txt
    local META=$ITEM/meta.txt
    local DATA=$ITEM/data.tsv
    
    if [[ ! ${options["f"]} && -d $ITEM ]];
    then
        echo "abow-import.sh: $INPUT_FILE: Already imported" > /dev/stderr;
        return;
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
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE' as '$UUID'"
    fi;
}

function import_directory {

    local INPUT_FILE=${1}
    
    if [[ ! -d "$INPUT_FILE" ]];
    then
        echo "abow-import.sh: $INPUT_FILE: Directory not found" > /dev/stderr;
        return;
    fi;

    for i in `find "$INPUT_FILE" -type f -name "*.txt"`; do
        import_file "$i";
    done;
}

function import_recursive {

    local INPUT_FILE=${1}
    
    if [[ -f "$INPUT_FILE" ]]; then
        import_file "$INPUT_FILE";
    elif [[ -d "$INPUT_FILE" ]]; then
        import_directory "$INPUT_FILE";
    else
        echo "abow-import.sh: $INPUT_FILE: File or directory not found" > /dev/stderr;
        return;
    fi;
}

args=${@}
args=${args//--recursive/-r}
args=${args//--verbose/-v}
args=${args//--force/-f}
args=${args//--help/-h} # TODO

shopt -s extglob
args=${args//--+([a-zA-Z0-9-])/-?}

declare -A options;
OPTSTRING="rvfh"

while getopts "$OPTSTRING" name $args; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

while (( $# )) ; do

    INPUT_FILE=${1}

    if [[ ${options["r"]} ]]; then
        import_recursive "$INPUT_FILE";
    fi;

    import_file "$INPUT_FILE";

    shift;
done;

