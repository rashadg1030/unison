# SQL error when pulling a remote Unison codebase

When pulling a remote unison codebase, like `unison-md5` for example:

```ucm
.> pull https://github.com/asoltysik/unison-md5:.releases._latest external.md5
```

This causes an SQL error.

On my machine, I get:

```
unison: SQLite3 returned ErrorCan'tOpen while attempting to perform open "/home/rashad/.cache/unisonlanguage/gitfiles/https$x3A$$x2F$$x2F$github$dot$com$x2F$asoltysik$x2F$unison-md5/.unison/v2/unison.sqlite3": unable to open database file
```
