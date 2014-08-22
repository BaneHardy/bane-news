#!/usr/bin/env tclsh

package require sqlite3;

sqlite3 news "./bane-news.db"
news eval {CREATE TABLE news(newstext text, timestamp text, author text)}
news close
