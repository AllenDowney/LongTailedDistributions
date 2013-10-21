#!/usr/bin/tclsh

if {[lindex $argv 0] == "color"} {
    set color 1
} else {
    set color 0
}

set title  "File Sizes from Irlam survey"
set xlabel "File size (bytes)"
set ylabel "Prob {file size > x}"

set xsize 4
set ysize 3

if {$color} {
    set outfile all.color
} else {
    set outfile all
}
set outfp [open $outfile.jgr w]

puts $outfp "newgraph"

#TITLE
puts $outfp "title : $title"
puts $outfp "  y 2"
puts $outfp "  font Helvetica fontsize 16"

#XAXIS
puts $outfp "xaxis size $xsize min 8 max 29 label : $xlabel"
puts $outfp "  font Helvetica fontsize 16 hjc"
puts $outfp "  no_auto_hash_marks"
puts $outfp "  hash_labels"
puts $outfp "  font Helvetica fontsize 16"

foreach pair {{10 1KB} {15 32KB} {20 1MB} {25 32MB}} {
    puts $outfp "  hash_at [lindex $pair 0]"
    puts $outfp "  hash_label at [lindex $pair 0] : [lindex $pair 1]"
}

#YAXIS
puts $outfp "yaxis size $ysize min -23 max 0 label : $ylabel"
puts $outfp "  font Helvetica fontsize 16"
puts $outfp "  no_auto_hash_marks"
puts $outfp "  hash_labels"
puts $outfp "  font Helvetica fontsize 16"

foreach pair {{0 1} {-5 1/32} {-8 1/256} {-12 2^-12} {-16 2^-16} {-20 2^-20}} {
    puts $outfp "  hash_at [lindex $pair 0]"
    puts $outfp "  hash_label at [lindex $pair 0] : [lindex $pair 1]"
}

#POINTS
puts $outfp "clip border"

puts $outfp "newcurve label : lognormal model"
puts $outfp "marktype none linetype dashed linethickness 2 gray 0.6" 
puts $outfp "pts"

set fp [open all.sizes.lognormal.model r]
while {[gets $fp line] != -1} {
    puts $outfp $line
}

puts $outfp "newcurve label : pareto model"
puts $outfp "marktype none linetype dotted"
puts $outfp "pts"

set fp [open all.sizes.pareto.model r]
while {[gets $fp line] != -1} {
    puts $outfp $line
}

puts $outfp "newcurve label : actual ccdf"
if {$color} {
    puts $outfp "marktype none linetype solid linethickness 2 color 1 0 0" 
} else {
    puts $outfp "marktype none linetype solid linethickness 2" 
}
puts $outfp "pts"

set fp [open all.clean.cdf.loglog.deres r]
while {[gets $fp line] != -1} {
    puts $outfp $line
}

puts $outfp "legend linelength 1 defaults x 10 y -18"
puts $outfp "font Helvetica fontsize 14"

close $outfp
exec jgraph $outfile.jgr > $outfile.eps
exec ghostview $outfile.eps &





