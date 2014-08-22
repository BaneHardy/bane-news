package require sqlite3;

namespace eval ::bane-news {
    variable ns [namespace current]

    # Config start
    #--------------------
    # Absolute path to the database file.
    set database "/home/bane/eggdrop/scripts/bane-news.db"
    #--------------------
    # Commands only work when invoked from these channels.
    # Management channels for add, del, show, help.
    set mgmtchans "#bane-mgmt1 #bane-mgmt2"
    # News channels for add announcement, show.
    set newschans "#bane-news1 #bane-news2"
    #--------------------
    # Trigger commands
    set trigger_news "!news"
    #--------------------
    # Config end

    # Binds start
    #--------------------
    bind pub -|- $trigger_news ${ns}::main
    #--------------------
    # Binds end

    proc checkmgmtchan {chan} {
        variable mgmtchans
        if {[lsearch [split [string tolower $mgmtchans]] [string tolower $chan]] == -1} {
            putquick "PRIVMSG $chan :Error: Invalid channel."
            return -code return
        }
    }

    proc checknewschan {chan} {
        variable newschans
        if {[lsearch [split [string tolower $newschans]] [string tolower $chan]] == -1} {
            putquick "PRIVMSG $chan :Error: Invalid channel."
            return -code return
        }
    }

    proc main {nick host hand chan text} {
        variable ns
        variable trigger_news
        set argv [split $text]
        set argc [llength $argv]
        if {$argc == 0} {
            ${ns}::show $chan 5
        } elseif {$argc == 1} {
            set n [lindex $argv 0]
            if {[string equal -nocase $n "help"]} {
                ${ns}::help $chan
            } elseif {[regexp {^[0-9]+$} $n] && $n > 0} {
                ${ns}::show $chan $n
            } else {
                putquick "PRIVMSG $chan :Error: $n is not a valid number. Help: $trigger_news help"
                return
            }
        } elseif {$argc > 1} {
            set command [lindex $argv 0]
            set parameters [join [lrange $argv 1 end]]
            if {[string equal -nocase $command "add"] && ![string equal $parameters ""]} {
                ${ns}::add $nick $chan $parameters
            } elseif {[string equal -nocase $command "del"] && ![string equal $parameters ""]} {
                ${ns}::del $chan $parameters
            } else {
                putquick "PRIVMSG $chan :Error: Invalid command or not enough arguments given. Help: $trigger_news help"
                return
            }
        }
    }

    proc add {nick chan text} {
        variable ns
        variable database
        variable newschans
        ${ns}::checkmgmtchan $chan
        set argv [split $text]
        set argc [llength $argv]
        set newstext [join $argv]
        sqlite3 news $database
        if {[news exists {SELECT timestamp FROM news WHERE newstext=$newstext}]} {
            putquick "PRIVMSG $chan :Error: This news already exists in the database."
        } else {
            set timestamp [clock seconds]
            news eval {INSERT INTO news VALUES($newstext, $timestamp, $nick)}
            foreach newschan [split $newschans] {
                putquick "PRIVMSG $newschan :\002Breaking News:\002"
                putquick "PRIVMSG $newschan :[clock format $timestamp -format "%Y-%m-%d"] - $newstext - $nick"
            }
        }
        news close
        return -code return
    }

    proc del {chan text} {
        variable ns
        variable database
        ${ns}::checkmgmtchan $chan
        set argv [split $text]
        set argc [llength $argv]
        sqlite3 news $database
        foreach id $argv {
            if {![string is integer $id]} {
                putquick "PRIVMSG $chan :Error: $id is not a valid number."
            } else {
                if {![news exists {SELECT timestamp FROM news WHERE rowid=$id}]} {
                    putquick "PRIVMSG $chan :Error: News with ID <$id> doesn't exist in the database."
                } else {
                    news eval {DELETE FROM news WHERE rowid=$id}
                    putquick "PRIVMSG $chan :Deleted news with ID <$id>."
                }
            }
        }
        news close
        return -code return
    }

    proc help {chan} {
        variable mgmtchans
        variable newschans
        variable trigger_news
        if {[lsearch [split [string tolower $newschans]] [string tolower $chan]] != -1} {
            putquick "PRIVMSG $chan :$trigger_news :: Shows 5 latest news."
            putquick "PRIVMSG $chan :$trigger_news <n> :: Shows <n> latest news. <n> needs to be a valid number > 0."
            putquick "PRIVMSG $chan :$trigger_news help :: You're reading it."
        }
        if {[lsearch [split [string tolower $mgmtchans]] [string tolower $chan]] != -1} {
            putquick "PRIVMSG $chan :$trigger_news add <text> :: Add <text> to database."
            putquick "PRIVMSG $chan :$trigger_news del <ID> :: Specify one or more IDs separated by spaces to delete news."
        }
        if {[lsearch [lsort -unique [concat [split [string tolower $newschans]] [split [string tolower $mgmtchans]]]] [string tolower $chan]] == -1} {
            putquick "PRIVMSG $chan :Error: Invalid channel."
        }
        return -code return
    }

    proc show {chan n} {
        variable ns
        variable database
        ${ns}::checknewschan $chan
        sqlite3 news $database
        if {![news exists {SELECT timestamp FROM news LIMIT 1}]} {
            putquick "PRIVMSG $chan :Error: Database is empty."
        } else {
            putquick "PRIVMSG $chan :\002News:\002"
            news eval {SELECT rowid AS newsid,newstext,timestamp,author FROM news WHERE rowid IN (SELECT rowid FROM news ORDER BY timestamp DESC LIMIT $n) ORDER BY timestamp ASC} {
                putquick "PRIVMSG $chan :$newsid - [clock format $timestamp -format "%Y-%m-%d"] - $newstext - $author"
            }
        }
        news close
        return -code return
    }
}

putlog "bane-news.tcl"
