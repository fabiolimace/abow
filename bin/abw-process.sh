#!/bin/bash
#
# This is a wrapper for `abw-process.awk`.
#
# Usage:
#
#    abw-process FILE [...]
#    abw-process FILE [...] > OUTPUT
#    abw-process -w OUTPUT FILE [...]
#    abw-process -f token,count FILE [...]
#    abw-process -o lang=pt,nostopwords,lower,ascii FILE [...]
#

declare -A options;
OPTSTRING="po:f:w:"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

INPUT_FILES="${@}"
FIELDS="-v FIELDS=${options["f"]}"
OPTIONS="-v OPTIONS=${options["o"]//=/:}"
WRITETO="-v WRITETO=${options["w"]:=/dev/stdout}"

if [[ -z "$INPUT_FILES" ]];
then
    echo "abw-process.sh: No input files" 1>&2;
    exit 1;
fi;

for i in $INPUT_FILES; do
    if [[ ! -f "$i" && "$i" != /dev/stdin ]];
    then
        echo "abw-process.sh: $i: File not found" 1>&2;
        exit 1;
    fi;
done;

if [[ ! ${options["f"]} =~ ^[[:alnum:],=]*$ ]];
then
    echo "abw-process.sh: Invalid fields string x" 1>&2;
    exit 1;
fi;

if [[ ! ${options["o"]} =~ ^[[:alnum:],=]*$ ]];
then
    echo "abw-process.sh: Invalid options string" 1>&2;
    exit 1;
fi;

BASEDIR=`dirname $0`
$BASEDIR/abw-process.awk -v PWD=$BASEDIR $FIELDS $OPTIONS $WRITETO $INPUT_FILES

