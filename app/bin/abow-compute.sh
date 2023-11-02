#!/bin/bash
#
# This is a wrapper for `abow-compute.awk`.
#
# Usage:
#
#    abow-compute [INPUT_FILE] [OUTPUT_FILE]
#

INPUT_FILE=${1:-/dev/stdin}
OUTPUT_FILE=${2:-/dev/stdout}

if [[ ! -f "$INPUT_FILE" ]];
then
    echo "abow-compute.sh: $INPUT_FILE: File not found" > /dev/stderr;
    exit 1;
fi;

BASEDIR=`dirname $0`

$BASEDIR/abow-compute.awk $INPUT_FILE > $OUTPUT_FILE

