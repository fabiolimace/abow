# ABoW

ABoW stands for Awk Bag of Words.

## Usage

Import files:

```bash
app/bin/abow-import.sh FILE [...]
```

Import files recursivelly:

```bash
app/bin/abow-import.sh --recursive DIRECTORY [...]
```

Import files recursivelly to a collection:

```bash
app/bin/abow-import.sh --recursive --collection COLLECTION DIRECTORY [...]
```

Where:

*   `FILE`: is a plain text file, optionally with a ".txt" suffix.
*   `DIRECTORY`: is a directory containing files with ".txt" suffix.
*   `COLLECTION`: is an arbitrary name for groups of imported files.

If no `COLLECTION` name is informed, the "default" collection is implied.

A single command can import one or more files or directories at once.

If a file exists, an error message is written to `/dev/stderr` related to that file. You can force to import files again using the `--force` option.

## Data structure

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
*   `25cc123e-66c5-35ac-8b32-bc8ef803abdf`: is a UUIDv3 derived from the original file path.

The short ID is just an abbreviated form of the UUIDv3. It is not meant to be globally unique, not even in the a collection scope.

The UUIDv3 is calculated using the original file path and the URL namespace specified by the RFC-4122. Note that the UUIDv3 will be different if the same file is imported again with a different name or from a different folder.


