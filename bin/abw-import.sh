#!/bin/bash
#
# Usage:
#
#    abw-import INPUT_FILE [FILE...]
#    abw-import -r DIRECTORY [DIRECTORY...]
#    abw-import -r -c COLLECTION DIRECTORY [...]
#

OPTSTRING="ic:rvh"
source `dirname $0`/abw-common.sh


function database_create {

    local COLLECTION=${1}
    local DATABASE=`database $COLLECTION`
    
    if [ -f "$DATABASE" ];
    then
        return;
    fi;
    
    sqlite3 "$DATABASE" <<EOF
CREATE TABLE text_ (uuid_ TEXT PRIMARY KEY, content_ TEXT);
CREATE TABLE meta_ (uuid_ TEXT PRIMARY KEY, hash_ TEXT, name_ TEXT, path_ TEXT, mime_ TEXT, date_ INTEGER, lines_ INTEGER, words_ INTEGER, bytes_ INTEGER, chars_ INTEGER);
CREATE TABLE data_ (uuid_ TEXT, token_ TEXT, type_ TEXT, count_ INTEGER, ratio_ REAL, format_ TEXT, case_ TEXT, length_ INTEGER, indexes_ TEXT);
CREATE UNIQUE INDEX text_index_ on text_ (uuid_);
CREATE UNIQUE INDEX meta_index_ on meta_ (uuid_);
EOF

}

function database_import_text {
    local COLLECTION="${1}"
    local TEXT="${2}"
    local UUID="${3}"
    local CONTENT=`cat "$TEXT"`
    local DATABASE=`database $COLLECTION`

    sqlite3 "$DATABASE" "INSERT INTO text_ (uuid_, content_) values ('$UUID', '$CONTENT');";
}

function database_import_meta {
    local COLLECTION="${1}"
    local META="${2}"
    local UUID="${3}"
    local HASH="`meta_value "$META" 'hash'`"
    local NAME="`meta_value "$META" 'name'`"
    local LANE="`meta_value "$META" 'path'`"
    local MIME="`meta_value "$META" 'mime'`"
    local DATE="`meta_value "$META" 'date'`"
    local LINES="`meta_value "$META" 'lines'`"
    local WORDS="`meta_value "$META" 'words'`"
    local BYTES="`meta_value "$META" 'bytes'`"
    local CHARS="`meta_value "$META" 'chars'`"
    local DATABASE=`database $COLLECTION`
    
    sqlite3 "$DATABASE" "INSERT INTO meta_ (uuid_, hash_, name_, path_, mime_, date_, lines_, words_, bytes_, chars_) values ('$UUID', '$HASH', '$NAME', '$LANE', '$MIME', '$DATE', '$LINES', '$WORDS', '$BYTES', '$CHARS');";
}


function database_import_data {
    local COLLECTION="${1}"
    local DATA="${2}"
    local UUID="${3}"
    local DATABASE=`database $COLLECTION`

    while read -r LINE; do
    
        if [[ -z "$HEAD" ]];
        then
            local HEAD="$LINE"
        fi;
    
        HEAD=`echo -n $HEAD | sed -E "s/\s/_,/g"`;
        LINE=`echo -n $LINE | sed -E "s/\s/','/g"`;
        
        sqlite3 "$DATABASE" "INSERT INTO data_ (uuid_, ${HEAD}_) values ('$UUID', '${LINE}');";
        
    done < "$DATA";

}

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
    local SQLI=
    
    if [[ -d $ROAD ]];
    then
        echo "abw-import.sh: $INPUT_FILE: Fire already imported" 1>&2;
        return;
    fi;
    
    mkdir --parents $ROAD;
    database_create "$COLLECTION"
    
    cp $INPUT_FILE $TEXT
    database_import_text $COLLECTION $TEXT $UUID
    
    echo -n > $META
    echo "collection=$COLLECTION" >> $META
    echo "uuid=$UUID" >> $META
    echo "hash=$HASH" >> $META
    echo "name=`basename $INPUT_FILE`" >> $META
    echo "path=`realpath $INPUT_FILE`" >> $META
    echo "mime=`file -bi $INPUT_FILE`" >> $META
    echo "date=`date '+%F %T'`" >> $META
    wc -lwcm "$INPUT_FILE" | awk '{ printf "lines=%d\nwords=%d\nbytes=%d\nchars=%d\n", $1, $2, $3, $4; }' >> $META
    database_import_meta $COLLECTION $META $UUID

    $BASEDIR/abw-process.sh $TEXT > $DATA
    
    if [[ ${options["v"]} ]]; then
        echo "Imported '$INPUT_FILE'"
    fi;
    database_import_data $COLLECTION $DATA $UUID
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

