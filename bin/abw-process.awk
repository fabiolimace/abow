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
    case /^[[:lower:]]+(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "L"; # Lower case: "word", "compound-word", "compound-WORD" and "compound-Word"
    case /^[[:upper:]][[:lower:]]*(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "C"; # Capitalized: "Word", "Compound-word", "Compound-WORD" and "Compound-Word"
    case /^[[:upper:]]+(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "U"; # Upper case: "WORD", "COMPOUND-word", "COMPOUND-WORD" and "COMPOUND-Word"
    default:
        return "NA";
    }
    
    # NOTE:
    # UPPERCASE words with a single character, for example "É", are treated as Capitalized words by this function.
    # The author considers it a very convenient behavior that helps to identify proper nouns and the beginning of
    # sentences, although he admits that it may not be intuitive. The order of the switch cases is important to
    # preserve this behavior.
}

function join(array,    i, result)
{
    for (i in array) {
        if (i == 1) result = array[i];
        else result = result "," array[i];
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

function get_stopwords_regex(lang,    stopwords_file, stopwords_regex, line) {

    stopwords_file=pwd "/../lib/lang/" lang "/stopwords.txt"

    while((getline line < stopwords_file) > 0) {

        # skip line started with #
        if (line ~ /^[[:space:]]*$/ || line ~ /^#/) continue;

        for (o in options) {
            switch (options[o]) {
            case "ascii":
                line = toascii(line);
                break;
            case "lower":
                line = tolower(line);
                break;
            case "upper":
                line = toupper(line);
                break;
            default:
                continue;
            }
        }

        if (stopwords_regex) stopwords_regex = stopwords_regex "|"
        stopwords_regex=stopwords_regex line;
    }

    if (!stopwords_regex) return "";
    else return "\\<(" stopwords_regex ")\\>";
}

BEGIN {

    pwd = PWD;
    split(FIELDS,fields,",");
    split(OPTIONS,options,",");

    lang = get_option("lang");
    stopwords_regex=get_stopwords_regex(lang);
}

NF {

    $0=" " $0 " "; # add spaces at both sides to make escapes easier.
    gsub(/ [\$€£@#]\</," \x1A&\x1A"); # escape at the start of words:       `$` `€` `£` `@` `#`
    gsub(/\>[\$¢°%] /,"\x1A&\x1A "); # escape at end of words:              `$` `¢` `°` `%`
    gsub(/\>[\$@&/.,':-]\</,"\x1A&\x1A"); # escape in the middle of words.  `$` `@` `&` `/` `.` `,` `'` `:` `-`
    
    $0 = gensub(/([[:punct:]])([[:punct:]])/,"\\1 \\2","g");
    $0 = gensub(/([^\x1A ])([[:punct:]])/,"\\1 \\2","g");
    $0 = gensub(/([[:punct:]])([^\x1A ])/,"\\1 \\2","g");
    gsub(/\x1A/,""); # remove all SUBSTITUTE characters (\x1A)

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

    for (o in options) {
        switch (options[o]) {
        case "noalpha":
            gsub(/[[:alpha:]]+/,"");
            break;
        case "nodigit":
            gsub(/[[:digit:]]+/,"");
            break;
        case "nopunct":
            gsub(/[[:punct:]]+/,"");
            break;
        case "nomixed":
            gsub(/([[:alpha:]]+([[:punct:][:digit:]]+[[:alpha:]]+)+|[[:digit:]]+([[:punct:][:alpha:]]+[[:digit:]]+)+)/,"");
            break;
        case "nostopwords":
            gsub(stopwords_regex,"");
            break;
        default:
            continue;
        }
    }

    for (i = 1; i <= NF; i++) {
        insert($i);
    }

    insert("<EOL>");
}

END {

    # start of operational checks #
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

    for (f in fields) {
        if (default_fields ~ "\\<" fields[f] "\\>" ) {
            printf "%s\t", toupper(fields[f]);
        }
    }
    printf "\n";
    
    for (token in counters) {

        count = counters[token];
        ratio = counters[token] / total;

        for (f in fields) {
            if (default_fields ~ "\\<" fields[f] "\\>" ) {
                switch (fields[f]) {
                case "token":
                    printf "%s\t", token
                    break;
                case "count":
                    printf "%d\t", count
                    break;
                case "ratio":
                    printf "%.9f\t", ratio
                    break;
                case "class":
                    printf "%s\t", character_class(token)
                    break;
                case "case":
                    printf "%s\t", letter_case(token)
                    break;
                case "length":
                    printf "%d\t", length(token)
                    break;
                case "indexes":
                    printf "%s\t", join(indexes[token])
                    break;
                default:
                    continue;
                }
            }
        }
        printf "\n";
    }
}

