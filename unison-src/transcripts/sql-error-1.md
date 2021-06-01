# SQL error on pull command when remote is ahead of local

First, to set up the scenario add a new type alias to a namespace and push to remote:

```ucm
.> cd .lib
.lib> alias.type ##Nat Nat
.lib> push ${repo}
```
Then we add another type alias to another namespace within the last one that was created, and push again:

```ucm
.lib> cd .lib2
.lib2> alias.type ##Int Int
.lib2> push ${repo}
```

This causes an SQL error.

On my machine, I get:

```
 query "PRAGMA journal_mode=WAL;"
(and crashed)

 query "PRAGMA journal_mode=WAL;" local codebase...
(and crashed)

unison: SQLite3 returned ErrorIO while attempting to perform prepare "PRAGMA journal_mode=WAL;": disk I/O error
```
