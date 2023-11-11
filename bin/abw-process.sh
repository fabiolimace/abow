#!/bin/bash
#
# This is a wrapper for `abw-process.awk`.
#
# Usage:
#
#    abw-process FILE [...]
#    abw-process FILE [...] > OUTPUT
#    abw-process -f token,count FILE [...]
#    abw-process -o lower,ascii FILE [...]
#

declare -A options;
OPTSTRING="po:f:"

while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

INPUT_FILES="${@:-/dev/stdin}"
FIELDS="-v FIELDS=${options["f"]}"
OPTIONS="-v OPTIONS=${options["o"]/=/:}"

for i in $INPUT_FILES; do
    if [[ ! -f "$i" && "$i" != /dev/stdin ]];
    then
        echo "abw-process.sh: $i: File not found" >> /dev/stderr;
        exit 1;
    fi;
done;

if [[ ! ${options["f"]} =~ [[:alpha:],]* ]];
then
    echo "abw-process.sh: $i: Invalid fields string" >> /dev/stderr;
    exit 1;
fi;

if [[ ! ${options["o"]} =~ [[:alpha:],]* ]];
then
    echo "abw-process.sh: $i: Invalid options string" >> /dev/stderr;
    exit 1;
fi;

BASEDIR=`dirname $0`
$BASEDIR/abw-process.awk -v PWD=$BASEDIR $FIELDS $OPTIONS $INPUT_FILES > /dev/stdout

