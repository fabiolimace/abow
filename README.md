# ABoW

ABoW stands for Awk Bag of Words.

## Usage

### Process files

Process files to /dev/stdout:

```bash
abow --process FILE [...]
```

Process files to an output file:

```bash
abow --process --output OUTPUT FILE [...]
```

Where:

*   `FILE`: is a plain text file, optionally with a ".txt" suffix.
*   `OUTPUT`: is a tab-separated value file, optionally with a ".tsv" suffix.

### List files

List all files:

```bash
abow --list
```

List files of a collection:

```bash
abow --list --collection COLLECTION
```

List files of a collection selecting the metadata fields:

```bash
abow --list --collection COLLECTION --meta "suid,collection,name,size,date"
```

### Show files

Show a `text.txt` file:

```bash
abow --show SHORT_ID
```

Show a `meta.txt` file:

```bash
abow --show --meta SHORT_ID
```

Show a `data.tsv` file:

```bash
abow --show --data SHORT_ID
```

### Search in files

Search in `text.txt` files:

```bash
abow --grep REGEX
```

Search in `meta.txt` files:

```bash
abow --grep -meta REGEX
```

Search in `data.tsv` files:

```bash
abow --grep -data REGEX
```

### Import files

Import files:

```bash
abow-import.sh FILE [...]
```

Import files recursivelly:

```bash
abow-import.sh --recursive DIRECTORY [...]
```

Import files recursivelly to a collection:

```bash
abow-import.sh --recursive --collection COLLECTION DIRECTORY [...]
```

Where:

*   `FILE`: is a plain text file, optionally with a ".txt" suffix.
*   `DIRECTORY`: is a directory containing files with ".txt" suffix.
*   `COLLECTION`: is an arbitrary name for groups of imported files.

If no `COLLECTION` name is informed, the "default" collection is implied.

A single command can import one or more files or directories at once.

If a file exists, an error message is written to `/dev/stderr` related to that file. You can force to import files again using the `--force` option.

## `data.tsv` file structure

The `data.tsv` file is a tab-separated value file containing the generated the bag of words.

Fields:

*   `TOKEN`: is a word, a punctuation symbol or an `<EOL>`.
*   `COUNT`: is the number of occurencies of the token in the text.
*   `RATIO`: is the COUNT divided by the sum occurrencies of all tokens in the text.
*   `CLASS`: is one of these POSIX character classes: 'A' for `[:alpha:]`, 'D' for `[:digit:]`, 'P' for `[:punct:]`, and 'NA' for none.
*   `CASE`: is one of these letter cases: 'L' for lower case, 'U' for upper case, 'C' for capitalized word, and 'NA' for none.
*   `LENGTH`: is the number of characters in the token.
*   `INDEXES`: is the list of all positions of the token in the text separated by commas.

Where:

*   `<EOL>`: is a symbol for the end of line.

If a token has only 1 character and this character is an uppercase letter, then this token is treated as a capitalized word; for example, the word "É" is a capitalized word.

No quotes are used in the output file to separate fields, despite Github's complaints about ["unclosed quoted fields"](https://docs.github.com/pt/repositories/working-with-files/using-files/working-with-non-code-files). Only end of lines (\n) and tabs (\t) are are utilized to separate records and fields, respectively. To learn why I choose TSV over CSV format, read this comparision between the two: https://github.com/eBay/tsv-utils/blob/master/docs/comparing-tsv-and-csv.md.

## `data` directory structure

The imported files are stored in the `data` folder.

The imported files are grouped in sub-folders called "collections" under the `data` folder.

```bash
tree data
```
```
data
└── default
    ├── 25cc123e
    │   └── 25cc123e-66c5-35ac-8b32-bc8ef803abdf
    │       ├── data.tsv
    │       ├── meta.txt
    │       └── text.txt
    └── 80a7c9ab
        └── 80a7c9ab-8f0c-31ab-9f72-251367cf6557
            ├── data.tsv
            ├── meta.txt
            └── text.txt
```

Where:

*   `data.tsv`: is a tab-separated value file containing the bag of words.
*   `meta.txt`: is a key-value file containing some properties.
*   `text.txt`: is a copy of the input text file.

And where:

*   `default`: is the a collection name.
*   `25cc123e`: is a short ID to derived from the file's UUIDv3.
*   `25cc123e-66c5-35ac-8b32-bc8ef803abdf`: is a UUIDv3 derived from the original file content.

The short ID is just an abbreviated form of the UUIDv3. It is not meant to be globally unique, not even in the a collection scope.

The UUIDv3 is calculated using the original file content and the custom namespace "33333333-3333-3333-3333-333333333333".

