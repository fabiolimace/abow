#!/bin/bash
#
# Usage:
#
#    abow-import INPUT_FILE [FILE...]
#    abow-import -r DIRECTORY [DIRECTORY...]
#    abow-import -r -c COLLECTION DIRECTORY [...]
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

# Equivalent to ASCII string: "3333333333333333"
NAMESPACE="33333333-3333-3333-3333-333333333333";

function hash {
    sha1sum ${1} | cut -c-40
}

function uuid {
    # Generate a UUIDv8 using the file hash. UUIDv8 is custom and free-form UUID
    echo -n ${1} | awk '{ print substr($0, 1, 8) "-" substr($0, 9, 4) "-8" substr($0, 14, 3) "-8" substr($0, 18, 3) "-" substr($0, 21, 12) }'
}

function import_file {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -f "$INPUT_FILE" ]];
    then
        echo "abow-import.sh: $INPUT_FILE: File not found" >> /dev/stderr;
        return;
    fi;
    
    local HASH=`hash "$INPUT_FILE"`
    local UUID=`uuid "$HASH"`
    local SUID=`echo $UUID | cut -d- -f1`
    local ITEM=$DATADIR/$COLLECTION/$SUID/$UUID;
    local TEXT=$ITEM/text.txt
    local META=$ITEM/meta.txt
    local DATA=$ITEM/data.tsv
    
    if [[ -d $ITEM && ! ${options["f"]} ]];
    then
        echo "abow-import.sh: $INPUT_FILE: Fire already imported to '$COLLECTION/$SUID/'" >> /dev/stderr;
        return;
    fi;
    
    mkdir --parents $ITEM;
    
    cp $INPUT_FILE $TEXT
    
    echo "collection=$COLLECTION" > $META
    echo "suid=$SUID" >> $META
    echo "uuid=$UUID" >> $META
    echo "path=$INPUT_FILE" >> $META
    echo "name=`basename $INPUT_FILE`" >> $META
    echo "hash=$HASH" >> $META
    echo "date=`date '+%F %T'`" >> $META
    echo "mime=`file -bi $INPUT_FILE`" >> $META
    echo "size=`wc -c $INPUT_FILE | cut -d" " -f1`" >> $META
   
    $BASEDIR/abow-process.sh -f -o $DATA $TEXT
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE' to '$COLLECTION/$SUID/'"
    fi;
}

function import_directory {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -d "$INPUT_FILE" ]];
    then
        echo "abow-import.sh: $INPUT_FILE: Directory not found" >> /dev/stderr;
        return;
    fi;

    for i in `find "$INPUT_FILE" -type f -name "*.txt"`; do
        import_file "$COLLECTION" "$i";
    done;
}

function import_recursive {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ -f "$INPUT_FILE" ]]; then
        import_file "$COLLECTION" "$INPUT_FILE";
    elif [[ -d "$INPUT_FILE" ]]; then
        import_directory "$COLLECTION" "$INPUT_FILE";
    else
        echo "abow-import.sh: $INPUT_FILE: File or directory not found" >> /dev/stderr;
        return;
    fi;
}

declare -A options;
OPTSTRING="ic:rvfh"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

while (( $# )) ; do

    INPUT_FILE=${1}
    COLLECTION=${options["c"]:=default}

    if [[ ${options["r"]} ]]; then
        import_recursive "$COLLECTION" "$INPUT_FILE";
    else
        import_file "$COLLECTION" "$INPUT_FILE";
    fi;

    shift;
done;

