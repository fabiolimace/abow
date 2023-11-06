#!/bin/bash
#
# This is a wrapper for `abw-process.awk`.
#
# Usage:
#
#    abw-process FILE [...]
#    abw-process FILE [...] > OUTPUT
#    abw-process -o OUTPUT FILE [...]
#

declare -A options;
OPTSTRING="po:f"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

INPUT_FILES="${@:-/dev/stdin}"
OUTPUT_FILE="${options["o"]:=/dev/stdout}"

for i in $INPUT_FILES; do
    if [[ ! -f "$i" && "$i" != /dev/stdin ]];
    then
        echo "abw-process.sh: $i: File not found" >> /dev/stderr;
        exit 1;
    fi;
done;

if [[ -f "$OUTPUT_FILE" && "$OUTPUT_FILE" != /dev/stdout && ! ${options["f"]} ]];
then
    echo "abw-process.sh: $OUTPUT_FILE: File already exists" >> /dev/stderr;
    exit 1;
fi;

BASEDIR=`dirname $0`
$BASEDIR/abw-process.awk $INPUT_FILES > $OUTPUT_FILE

