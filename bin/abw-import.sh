#!/bin/bash
#
# Usage:
#
#    abw-import INPUT_FILE [FILE...]
#    abw-import -r DIRECTORY [DIRECTORY...]
#    abw-import -r -c COLLECTION DIRECTORY [...]
#

OPTSTRING="ic:rvh"
source ./abw-common.sh

function import_file {

    local COLLECTION=${1}
    local INPUT_FILE=${2}
    
    if [[ ! -f "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: File not found" 1>&2;
        return;
    fi;
    
    if [[ ! -s "$INPUT_FILE" ]];
    then
        echo "abw-import.sh: $INPUT_FILE: File is empty" 1>&2;
        return;
    fi;
    
    local HASH=`hash "$INPUT_FILE"`
    local UUID=`uuid "$HASH"`
    local ROAD=`road "$COLLECTION" "$UUID"`;
    local TEXT=$ROAD/text.txt
    local META=$ROAD/meta.txt
    local DATA=$ROAD/data.tsv
    
    if [[ -d $ROAD ]];
    then
        echo "abw-import.sh: $INPUT_FILE: Fire already imported" 1>&2;
        return;
    fi;
    
    mkdir --parents $ROAD;
    
    cp $INPUT_FILE $TEXT
    
    echo -n > $META
    echo "collection=$COLLECTION" >> $META
    echo "uuid=$UUID" >> $META
    echo "hash=$HASH" >> $META
    echo "path=`realpath $INPUT_FILE`" >> $META
    echo "name=`basename $INPUT_FILE`" >> $META
    echo "date=`date '+%F %T'`" >> $META
    echo "mime=`file -bi $INPUT_FILE`" >> $META
    wc -lwcm "$INPUT_FILE" | awk '{ printf "lines=%d\nwords=%d\nbytes=%d\nchars=%d\n", $1, $2, $3, $4; }' >> $META

    $BASEDIR/abw-process.sh $TEXT > $DATA
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE'"
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

