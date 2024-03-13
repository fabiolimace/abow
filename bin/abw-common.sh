#!/bin/bash
#
# Common variables and functions for ABW.
#
# You MUST declare OPTSTRING before sourcing.
#
# Usage:
# 
#     OPTSTRING="abcd:efg:h"
#     source ./abw-common.sh
#

BASEDIR=`dirname $0`
DATADIR="$BASEDIR/../data"

declare -A options;
while getopts "$OPTSTRING" name ${@}; do
      if [[ ${OPTARG} ]]; then
        options[${name}]=${OPTARG};
      else
        options[${name}]=${name};
      fi;
done;
shift $(( ${OPTIND} - 1 ));

# wildcard pad
function pad {
    local UUID=${1}
    local SIZE=36
    
    if [ "${#UUID}" -lt $SIZE ]; then
        # padding short UUID with wildcards '?'
        UUID=`printf "%-${SIZE}s" $UUID | tr " " "?"`
    fi
    printf "$UUID"
}

# get file hash
function hash {
    local FILE=${1}
    sha1sum ${FILE} | head -c 40
}

# get hash UUID
function uuid {
    local HASH=${1}
    # generate a UUIDv8 using the first 32 chars of the file hash
    printf "%s-%s-%s%s-%s%s-%s" ${HASH:0:8} ${HASH:8:4} '8' ${HASH:13:3} '8' ${HASH:17:3} ${HASH:20:12}
}

# get file path
function road {
    local COLLECTION=${1}
    local UUID=${2}
    printf "$DATADIR/%s/%s/%s/%s" "${COLLECTION}" "${UUID:0:2}" "${UUID:2:2}" "${UUID}";
}

function get_meta_value {
    local META_FILE="${1}"
    local KEY="${2}"
    grep "$KEY=" "$META_FILE" | cut -d= -f2
}

