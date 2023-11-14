#!/usr/bin/gawk -f

# Notes:
#   * Files encoded using MAC-UTF-8 must be normalized to UTF-8.
#   * Non-breakin spaces (NBSP, 0xA0) must be converted to regular spaces.

function character_class(token)
{
    switch (token) {
    case /^[[:alpha:]-]+$/:
        return "A"; # Alpha (with hyphen)
    case /^[[:digit:]]+$/:
        return "D"; # Digit (only)
    case /^[[:punct:]]+$/:
        return "P"; # Punct (only)
    default:
        return "M"; # Mixed (alpha, digit, and punct)
    }
    
    # NOTE:
    # This function returns NA to words that contain "accented" characters encoded
    # with MAC-UTF-8. You must normilize the input files to regular UTF-8 encoding.
}

function letter_case(token)
{
    switch (token) {
    case /^[[:lower:]]+(-([[:alpha:]]+))*$/:
        return "L"; # Lower case: "word", "compound-wOrD"
    case /^[[:upper:]][[:lower:]]*(-([[:alpha:]]+))*$/:
        return "S"; # Start case: "Word", "Compound-wOrD"
    case /^[[:upper:]]+(-([[:alpha:]]+))*$/:
        return "U"; # Upper case: "WORD", "COMPOUND-wOrD"
    case /^[[:alpha:]][[:lower:]]+([[:upper:]][[:lower:]]+)+$/:
        return "C"; # Camel case: "compoundWord", "CompoundWord"
    case /^([[:lower:]]+(_[[:lower:]]+)+|[[:upper:]]+(_[[:upper:]]+)+)$/:
        return "O"; # Snake case: "compound_word", "COMPOUND_WORD"
    case /^[[:alpha:]]+(-([[:alpha:]]+))*$/:
        return "M"; # Mixed case: "wOrD", "cOmPoUnD-wOrD"
    default:
        return "NA";
    }
    
    # NOTE:
    # UPPERCASE words with a single character, for example "É", are treated as first case words by this function.
    # The author considers it a very convenient behavior that helps to identify proper nouns and the beginning of
    # sentences, although he admits that it may not be intuitive. The order of the switch cases is important to
    # preserve this behavior.
}

function join(array, sep,    i, result)
{
    if (!sep) sep=",";
    for (i in array) {
        if (i == 1) result = array[i];
        else result = result sep array[i];
    }
    return result
}

function insert(token) {
    total++;
    counters[token]++;
    indexes[token][counters[token]]=total;
}

function toascii(string) {

    # Transliterate Unicode
    # Latin-1 Supplement chars
    gsub(/[ÀÁÂÃÄÅ]/,"A", string);
    gsub(/[ÈÉÊË]/,"E", string);
    gsub(/[ÌÍÎÏ]/,"I", string);
    gsub(/[ÒÓÔÕÖ]/,"O", string);
    gsub(/[ÙÚÛÜ]/,"U", string);
    gsub(/Ý/,"Y", string);
    gsub(/Ç/,"C", string);
    gsub(/Ñ/,"N", string);
    gsub(/Ð/,"D", string);
    gsub(/Ø/,"OE", string);
    gsub(/Þ/,"TH", string);
    gsub(/Æ/,"AE", string);
    gsub(/[àáâãäåª]/,"a", string);
    gsub(/[èéêë]/,"e", string);
    gsub(/[ìíîï]/,"i", string);
    gsub(/[òóôõöº]/,"o", string);
    gsub(/[ùúûü]/,"u", string);
    gsub(/[ýÿ]/,"y", string);
    gsub(/ç/,"c", string);
    gsub(/ñ/,"n", string);
    gsub(/ð/,"d", string);
    gsub(/ø/,"oe", string);
    gsub(/þ/,"th", string);
    gsub(/ae/,"ae", string);
    gsub(/ß/,"ss", string);
    # Replace non-ASCII with SUB (0x1A)
    gsub(/[^\x00-\x7E]/,"\x1A", string);

    return string;
}

function get_option(key) {
    for (o in options) {
        if (options[o] ~ "^" key "$") return 1;
        if (options[o] ~ "^" key ":") return substr(options[o], index(options[o], ":") + 1);
    }
    return 0;
}

function get_stopwords_regex(lang,    file, regex, line) {

    file=pwd "/../lib/lang/" lang "/stopwords.txt"
   
    regex=""
    while((getline line < file) > 0) {

        # skip line started with #
        if (line ~ /^[[:space:]]*$/ || line ~ /^#/) continue;

        regex=regex "|" line;
    }

    # remove leading pipe
    regex=substr(regex,2);

    return "^(" regex ")$"
}

function get_sort_order(    sort_order) {
    sort_order="@unsorted"
    for (o in options) {
        switch (options[o]) {
        case /^asc:/:
            if (get_option("asc")=="token") sort_order="@ind_str_asc";
            if (get_option("asc")=="count") sort_order="@val_num_asc";
            break;
        case /^desc:/:
            if (get_option("desc")=="token") sort_order="@ind_str_desc";
            if (get_option("desc")=="count") sort_order="@val_num_desc";
            break;
        default:
            continue;
        }
    }
    return sort_order;
}

# separates all tokens by spaces
function separate_tokens (    line) {

    line=" " $0 " "; # add spaces at both sides to make escapes easier.
    gsub(/ [\$€£@#]\</," \x1A&\x1A", line); # escape at the start of words:       `$` `€` `£` `@` `#`
    gsub(/\>[\$¢°%] /,"\x1A&\x1A ", line); # escape at end of words:              `$` `¢` `°` `%`
    gsub(/\>[\$@&\/.,':-]\</,"\x1A&\x1A", line); # escape in the middle of words.  `$` `@` `&` `/` `.` `,` `'` `:` `-`

    line=gensub(/([[:punct:]])([[:punct:]])/,"\\1 \\2","g", line);
    line=gensub(/([^\x1A ])([[:punct:]])/,"\\1 \\2","g", line);
    line=gensub(/([[:punct:]])([^\x1A ])/,"\\1 \\2","g", line);

    gsub(/\x1A/,"", line); # remove SUBSTITUTE characters (\x1A)
    gsub(/[[:space:]]+/," ", line); # squeeze groups of spaces
    gsub(/^[[:space:]]+|[[:space:]]+$/,"", line); # trim line

    $0 = line;
}

function remove_tokens(options,    i) {

    IGNORECASE=1;

    for (o in options) {
        switch (options[o]) {
        case "noalpha":
            for(i = 1; i <= NF; i++) {
                if ($i ~ /^[[:alpha:]-]+$/) $i = "";
            }
            break;
        case "nodigit":
            for(i = 1; i <= NF; i++) {
                if ($i ~ /^[[:digit:]]+$/) $i = "";
            }
            break;
        case "nopunct":
            for(i = 1; i <= NF; i++) {
                if ($i ~ /^[[:punct:]]+$/) $i = "";
            }
            break;
        case "nomixed":
            for(i = 1; i <= NF; i++) {
                if ($i !~ /^([[:alpha:]-]+|[[:digit:]]+|[[:punct:]]+)$/) $i = "";
            }
            break;
        case "nostopwords":
            for(i = 1; i <= NF; i++) {
                if ($i ~ stopwords_regex) $i = "";
            }
            break;
        default:
            continue;
        }
    }
    $0=$0 # force update

    IGNORECASE=0;
}

function change_tokens(options) {
    for (o in options) {
        switch (options[o]) {
        case "ascii":
            $0 = toascii($0);
            break;
        case "lower":
            $0 = tolower($0);
            break;
        case "upper":
            $0 = toupper($0);
            break;
        default:
            continue;
        }
    }
}

function basename(file) {
    sub("^.*/", "", file)
    return file
}

function basedir(file) {
    sub("/[^/]+$", "", file)
    return file
}

BEGIN {

    pwd = PWD;
    split(FIELDS,fields,",");
    split(OPTIONS,options,",");

    lang = get_option("lang");
    eol = !get_option("noeol");
    sort_order=get_sort_order();
    if (get_option("nostopwords")) stopwords_regex=get_stopwords_regex(lang);
}

BEGINFILE {
    total = 0;
    delete counters;
    delete indexes;
}

NF {

    separate_tokens();

    change_tokens(options);

    remove_tokens(options);

    for (i = 1; i <= NF; i++) {
        insert($i);
    }

    if (eol) insert("<EOL>");
}

ENDFILE {

    output=WRITETO;
    filedir=basedir(FILENAME)
    filename=basename(FILENAME)
    sub(/:filedir/, filedir, output);
    sub(/:filename/, filename, output);

    # start of operational checks #
    sum=0
    for (k in counters) {
        sum += counters[k];
    }    
    if (sum != total) {
        print "Wrong sum of counts" > "/dev/stderr";
        exit 1;
    }
    # end of operational checks #

    default_fields="token,count,ratio,class,case,length,indexes";
    if (!length(fields)) split(default_fields, fields, ",");

    sep=""
    for (f in fields) {
        if (default_fields ~ "\\<" fields[f] "\\>" ) {
            printf "%s%s", sep, toupper(fields[f]) > output;
        }
        sep="\t"
    }
    printf "\n" > output;
    
    PROCINFO["sorted_in"]=sort_order;
    for (token in counters) {

        sep = ""
        count = counters[token];
        ratio = counters[token] / total;

        PROCINFO["sorted_in"]="@unsorted"
        for (f in fields) {
            if (default_fields ~ "\\<" fields[f] "\\>" ) {
                switch (fields[f]) {
                case "token":
                    printf "%s%s", sep, token > output;
                    break;
                case "count":
                    printf "%s%d", sep, count > output;
                    break;
                case "ratio":
                    printf "%s%.9f", sep, ratio > output;
                    break;
                case "class":
                    printf "%s%s", sep, character_class(token) > output;
                    break;
                case "case":
                    printf "%s%s", sep, letter_case(token) > output;
                    break;
                case "length":
                    printf "%s%d", sep, length(token) > output;
                    break;
                case "indexes":
                    printf "%s%s", sep, join(indexes[token]) > output;
                    break;
                default:
                    continue;
                }
            }
            sep="\t"
        }
        printf "\n" > output;
    }
    PROCINFO["sorted_in"]="@unsorted"
}

