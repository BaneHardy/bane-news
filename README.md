bane-news
=========

Install this news script in five simple steps:

1. Put bane-news-create-database.tcl and bane-news.tcl in the eggdrop scripts
   directory.

2. Execute bane-news-create-database.tcl. This creates an empty sqlite3
   database file bane-news.db in the current directory. This file is used for
   storing the news later. Afterwards the tcl file may be deleted.

3. Edit the config block in bane-news.tcl with your favourite editor.

4. Source bane-news.tcl in the eggdrop config file:
   source scripts/bane-news.tcl

5. Rehash or restart the eggdrop.
