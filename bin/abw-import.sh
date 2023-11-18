#!/bin/bash
#
# Usage:
#
#    abw-import INPUT_FILE [FILE...]
#    abw-import -r DIRECTORY [DIRECTORY...]
#    abw-import -r -c COLLECTION DIRECTORY [...]
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

function hash {
    sha1sum ${1} | head -c 40
}

function uuid {
    # Generate a UUIDv8 using the file hash. UUIDv8 is custom and free-form UUID
    printf "%s-%s-%s%s-%s%s-%s\n" ${1:0:8} ${1:8:4} '8' ${1:13:3} '8' ${1:17:3} ${1:20:12}
}

function import_file {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -f "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: File not found" 1>&2;
        return;
    fi;
    
    local HASH=`hash "$INPUT_FILE"`
    local UUID=`uuid "$HASH"`
    local SUID=`echo $UUID | cut -d- -f1`
    local ITEM=$DATADIR/$COLLECTION/$SUID/$UUID;
    local TEXT=$ITEM/text.txt
    local META=$ITEM/meta.txt
    local DATA=$ITEM/data.tsv
    
    if [[ -d $ITEM ]];
    then
        echo "abw-import.sh: $INPUT_FILE: Fire already imported to '$COLLECTION/$SUID/'" 1>&2;
        return;
    fi;
    
    mkdir --parents $ITEM;
    
    cp $INPUT_FILE $TEXT
    
    echo "collection=$COLLECTION" > $META
    echo "suid=$SUID" >> $META
    echo "uuid=$UUID" >> $META
    echo "path=`realpath $INPUT_FILE`" >> $META
    echo "name=`basename $INPUT_FILE`" >> $META
    echo "hash=$HASH" >> $META
    echo "date=`date '+%F %T'`" >> $META
    echo "mime=`file -bi $INPUT_FILE`" >> $META
    wc -lwcm "$INPUT_FILE" | awk '{ printf "lines=%d\nwords=%d\nbytes=%d\nchars=%d\n", $1, $2, $3, $4; }' >> $META

    $BASEDIR/abw-process.sh $TEXT > $DATA
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE' to '$COLLECTION/$SUID/'"
    fi;
}

function import_directory {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -d "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: Directory not found" 1>&2;
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
        echo "abw-import.sh: $INPUT_FILE: File or directory not found" 1>&2;
        return;
    fi;
}

declare -A options;
OPTSTRING="ic:rvh"

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

