#!/usr/bin/tclsh

set file [lindex $argv 0]

if {$file == ""} {
    set fp stdin
} else {
    set fp [open $file r]
}

gets $fp line
set lastsize [lindex $line 0]
set lastreps [lindex $line 1]
set total 0

while {[gets $fp line] != -1} {
    set size [lindex $line 0]
    set reps [lindex $line 1]

    if {$size == $lastsize} {
	incr total $reps
    } else {
        puts "$lastsize\t$total"
        set total $reps
    }
    set lastsize $size
    set lastreps $reps
}
