#!/usr/bin/gawk -f

# Notes:
#   * Files encoded using MAC-UTF-8 must be normalized to UTF-8.
#   * Non-breakin spaces (NBSP, 0xA0) must be converted to regular spaces.

function token_type(token)
{
    return toascii(tolower(token));
}

function token_format(token)
{
    switch (token) {
    case /^[[:alpha:]-]+$/:
        return "W"; # Word format: all-letter token (with hyphen)
    case /^[[:digit:]]+$/:
        return "N"; # Number format: all-digit token
    case /^[[:punct:]]+$/:
        return "P"; # Punct format: all-punct token
    default:
        return "NA"; # None of the above
    }
    
    # NOTE:
    # This function returns NA to words that contain "accented" characters encoded
    # with MAC-UTF-8. You must normilize the input files to regular UTF-8 encoding.
}

function token_case(token)
{
    switch (token) {
    case /^[[:lower:]]+(-([[:alpha:]]+))*$/:
        return "L"; # Lower case: "word", "compound-wOrD"
    case /^[[:upper:]][[:lower:]]*(-([[:alpha:]]+))*$/:
        return "S"; # Start case: "Word", "Compound-wOrD"
    case /^[[:upper:]]+(-([[:alpha:]]+))*$/:
        return "U"; # Upper case: "WORD", "COMPOUND-wOrD"
    case /^[[:upper:]]?[[:lower:]]+([[:upper:]][[:lower:]]+)+$/:
        return "C"; # Camel case: "compoundWord", "CompoundWord"
    case /^[[:alpha:]]+(-([[:alpha:]]+))*$/:
        return "M"; # Mixed case: "wOrD", "cOmPoUnD-wOrD"
    default:
        return "NA"; # None of the above
    }
    
    # NOTE:
    # UPPERCASE words with a single character, for example "É", are treated as first case words by this function.
    # The author considers it a very convenient behavior that helps to identify proper nouns and the beginning of
    # sentences, although he admits that it may not be intuitive. The order of the switch cases is important to
    # preserve this behavior.
}

function insert_token(token)
{
    idx++;
    tokens[idx]=token;
    counters[token]++;

    if (!types[token]) types[token] = token_type(token);
    if (!formats[token]) formats[token] = token_format(token);
    if (!cases[token]) cases[token] = token_case(token);

    if (!indexes[token]) indexes[token] = idx;
    else indexes[token] = indexes[token] "," idx;
}

function toascii(string) {

    # Unicode Latin-1 Supplement
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

    # Windows-1252 specials
    gsub(/ß/,"ss", string);

    # Replace non-ASCII with SUB (0x1A)
    gsub(/[^\x00-\x7E]/,"\x1A", string);

    return string;
}

function get_stopwords_regex(    file, regex, line) {

    if (!option_value("stopwords")) {
        return /^$/;
    }

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

# separates all tokens by spaces
function separate_tokens() {

    line=" " $0 " "; # Add spaces at both sides to make the tokenization easier.
    
    # Separate all puncts from each other.
    # It must be done twice and before the other operations.
    line=gensub(/([[:punct:]])([[:punct:]])/,"\\1 \\2","g", line);
    line=gensub(/([[:punct:]])([[:punct:]])/,"\\1 \\2","g", line);
    
    # Protect some puncts right before words: [ `#` `@` `$` `%` `&` `°` `+` `-` ]
    # The SUBSTITUTE character is used here to protect the list of puncts above.
    line=gensub(/([[:space:]])([\x23@$%&°+-]+)/,"\\1\x1A\\2","g", line);
    
    # Protect some puncts right after words: [ `#` `@` `$` `%` `&` `°` `+` `-` ]
    # The SUBSTITUTE character is used here to protect the list of puncts above.
    line=gensub(/([\x23@$%&°+-]+)([[:space:]])/,"\\1\x1A\\2","g", line);

    # Separate all the other puncts in the start of words.
    line=gensub(/([[:space:]][[:punct:]]+)/,"\\1 ","g", line);
    
    # Separate all the other puncts in the end of words.
    line=gensub(/([[:punct:]]+[[:space:]])/," \\1","g", line);

    gsub(/\x1A/,"", line); # Remove all SUBSTITUTE characters
    gsub(/[[:space:]]+/," ", line); # Squeeze groups of spaces
    gsub(/^[[:space:]]+|[[:space:]]+$/,"", line); # trim line
    
    $0 = line;
}

function generate_records(    count, ratio, sum, sep, row, f, k)
{    
    # start of operational checks #
    sum=0
    for (k in counters) {
        sum += counters[k];
    }    
    if (sum != length(tokens)) {
        print "Wrong sum of counts" > "/dev/stderr";
        exit 1;
    }
    # end of operational checks #
 
    row=0
    PROCINFO["sorted_in"]=sort_order;
    for (token in counters) {

    	row++;
        sep = ""
        count = counters[token];
        ratio = count / length(tokens);

        PROCINFO["sorted_in"]="@unsorted"
        for (f in fields) {
                if (fields[f]["value"] == 0) continue;
                switch (fields[f]["key"]) {
                case "token":
                    records[row]["token"] = token;
                    break;
                case "type":
                    records[row]["type"]= types[token];
                    break;
                case "count":
                    records[row]["count"] = count;
                    break;
                case "ratio":
                    records[row]["ratio"] = ratio;
                    break;
                case "format":
                    records[row]["format"] = formats[token];
                    break;
                case "case":
                    records[row]["case"] = cases[token];
                    break;
                case "length":
                    records[row]["length"] = length(token);
                    break;
                case "indexes":
                    records[row]["indexes"] = indexes[token];
                    break;
                default:
                    continue;
                }
            sep="\t"
        }
    }
    PROCINFO["sorted_in"]="@unsorted"
}

function print_records(    r, f, sep)
{
    if (length(records)) {
        sep = ""
        for (f in fields) {
            if (fields[f]["value"] == 0) continue;
            printf "%s%s", sep, toupper(fields[f]["key"]) > output;
            sep = "\t"
        }
        printf "\n" > output;

        for (r in records) {
         	sep = ""
        	for (f in fields) {
                if (fields[f]["value"] == 0) continue;
    	    	printf "%s%s", sep, records[r][fields[f]["key"]] > output;
    		    sep = "\t"
    	    }
            printf "\n" > output;
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

function parse_confs(    file, line, string)
{
    file=pwd "/../abw.conf"
   
    string=""
    while((getline line < file) > 0) {

        # skip comments 
        gsub(/#.*$/,"", line);

        # skip invalid lines
        if (line !~ /^[[:space:]]*[[:alnum:]]+[[:space:]]*=[[:space:]]*[[:alnum:]]+[[:space:]]*$/) continue;
        if (!string) string = line;
        else string=string "," line;
    }

    parse_fields(FIELDS, fields);
    if (length(fields) == 0) {
        parse_fields(string, fields);
    }

    parse_options(OPTIONS, options);
    if (length(options) == 0) {
        parse_options(string, options);
    }
}

function parse_fields(string, fields,    default_string)
{
    gsub(":","=",string);
    default_string="token,type,count,ratio,format,case,length,indexes";
    if (!string) string = default_string;
    parse_key_values(string, fields, default_string);
}

function parse_options(string, options,    default_string)
{
    gsub(":","=",string);
    default_string="ascii=0,lower=0,upper=0,stopwords=1,lang=none,eol=1,asc=none,desc=none";
    if (!string) string = default_string;
    parse_key_values(string, options, default_string); 
}

# Option formats: 'key' or 'key:value'
# If the format is 'key', name is 'key' and value is '1'
# If the format is 'key:value', name is 'key' and value is 'value'
function parse_key_values(string, keyvalues,     default_string, items, i, key, value, splitter)
{
    split(string, items, ",");
    for (i in items)
    {
        gsub(/=.*$/, "", items[i]);
        if (default_string !~ "\\<" items[i] "\\>") {
            gsub("\\<" items[i] "\\>(=[^,]*)?", "", string);
        }
    }

    gsub(",+", ",", string);
    gsub("^,|,$", "", string);

    split(string, items, ",");
    for (i in items)
    {
        if (items[i] !~ "=" ) {
            key = items[i];
            value = 1;
        } else {
            splitter = index(items[i], "=");
            key = substr(items[i], 0, splitter - 1);
            value = substr(items[i], splitter + 1);
        }
        keyvalues[i]["key"] = key;
        keyvalues[i]["value"] = value;
    }
}

function get_sort_order(    sort_order)
{
    sort_order="@unsorted"
    for (o in options) {
        switch (options[o]["key"]) {
        case "asc":
            if (options[o]["value"] == "token") sort_order = "@ind_str_asc";
            if (options[o]["value"] == "count") sort_order = "@val_num_asc";
            break;
        case "desc":
            if (options[o]["value"] == "token") sort_order = "@ind_str_desc";
            if (options[o]["value"] == "count") sort_order = "@val_num_desc";
            break;
        default:
            continue;
        }
    }
    return sort_order;
}

function remove_stopwords(    i)
{
    IGNORECASE=1;
    for (i = 1; i <= NF; i++) {
        if ($i ~ stopwords_regex) $i = "";
    }
    IGNORECASE=0;
}

function transform_line()
{
    for (o in options) {
        switch (options[o]["key"]) {
        case "ascii":
            if (options[o]["value"] == 1) $0 = toascii($0);
            break;
        case "lower":
            if (options[o]["value"] == 1) $0 = tolower($0);
            break;
        case "upper":
            if (options[o]["value"] == 1) $0 = toupper($0);
            break;
        case "stopwords":
            if (options[o]["value"] == 0) remove_stopwords();
            break;
        default:
            continue;
        }
    }
}

function option_value(key,    o) {
    for (o in options) {
        if (options[o]["key"] == key) return options[o]["value"];
    }
    return 0;
}

BEGIN {

    pwd = PWD;
    parse_confs();

    eol = option_value("eol");
    lang = option_value("lang");

    sort_order = get_sort_order();
    stopwords_regex = get_stopwords_regex();
}

BEGINFILE {
    idx = 0;
    delete tokens;
    delete types;
    delete counters;
    delete formats;
    delete cases;
    delete indexes;
    delete records;
}

NF {

    transform_line();
    separate_tokens();

    for (i = 1; i <= NF; i++) {
        insert_token($i);
    }

    if (eol) insert_token("<eol>");
}

ENDFILE {

    output=WRITETO;
    filedir=basedir(FILENAME)
    filename=basename(FILENAME)
    sub(/:filedir/, filedir, output);
    sub(/:filename/, filename, output);
 
    generate_records();
    print_records();

}


