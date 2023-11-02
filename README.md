# ABoW

ABoW stands for Awk Bag of Words.

Usage:

```bash
app/bin/abow-import.sh -r file.txt
```

Output:

```bash
tree app/database
```
```
app/database/
├── 55aa5322
│   └── 55aa5322-5a71-479c-aa6c-1b1f43ca61dd
│       ├── data.tsv
│       ├── meta.txt
│       └── text.txt
```

Where:

*   data.tsv: is a tab-separated value file containing the bag of words.
*   meta.txt: is a key-value file containing some properties.
*   text.txt: is a copy of the input text file.

And where:
*   55aa5322-5a71-479c-aa6c-1b1f43ca61dd: is a UUIDv3 of the file directory and name.
*   55aa5322: is a short ID to derived from the UUIDv3.


