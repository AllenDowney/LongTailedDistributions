#!/bin/sh
#
# sizes: interactive script to measure file sizes.
#
# Should preferably, though not essentially, be run as root.
#
# Tested on:
#     AIX 3.2
#     DEC OSF/1 1.3
#     HP-UX 8.02
#     NetBSD 0.9
#     SunOS 4.1.2, 5.1, 5.3.

ME=downey@colby.edu
TMP=/tmp/sizes

echo "This program gathers statistics on file sizes that can be used"
echo "to help design and tune file systems."
echo
echo "'df' is used to identify locally mounted file systems.  You are"
echo "given the opportunity to exclude some of these file systems."
echo "'find' then generates a list of file sizes and the results are"
echo "summarized.  This program may be safely aborted at any time."
echo
echo "Please exclude CD-ROM file systems from the list below."
echo "Don't worry, 'find' will not cross NFS or other mount points."

# Search for disks and record the mount points

echo
echo "Press return to search for disks"
read junk
echo "Searching for locally mounted disks ..."

df | \
sed 's|\(/[A-Za-z0-9_/\-]*\)[^/]*\(/[A-Za-z0-9_/\-]*\).*|\1 \2|
     /\/dev\// !d
     s|\(.*\) \(.*/dev/.*\)|\2 \1|' > $TMP.df
DISKS=`awk '{print $1}' $TMP.df`
MPTS=`awk '{print $2}' $TMP.df`
rm -f $TMP.*
if [ `echo $DISKS | wc -w` -ne `echo $MPTS | wc -w` ]; then
    echo "Unable to identify disks!"
    exit
fi

# Give the user a chance to skip some of the disks

i=1
for m in $MPTS; do
    if [ -d $m ]; then
        NUMS="$NUMS $i"
    fi
    i=`expr $i + 1`
done

echo
while :; do
    if [ -z "$NUMS" ]; then
        echo "No disks!"
        exit
    fi
    echo "       device        mount point"
    for i in $NUMS; do
        d=`echo $DISKS | awk '{print $'$i'}'`
        m=`echo $MPTS | awk '{print $'$i'}'`
        echo "    $i)" $d "  " $m
    done
    echo
    echo "Enter number of disk to ignore, or return to start processing"
    read nums
    if [ -z "$nums" ]; then break; fi
    for n in $nums; do
        OLD_NUMS=$NUMS
        NUMS=
        for i in $OLD_NUMS; do
            if [ "$n" -ne $i ]; then
                NUMS="$NUMS $i"
            fi
        done
    done
done

# Work out find flags to limit search to current disk and to list files

echo > $TMP.f

# 4.3 BSD and friends
find $TMP.f -type f -xdev -print > /dev/null 2>&1 && MFLAG="-xdev"
# SVR3 and friends
find $TMP.f -type f -mount -print > /dev/null 2>&1 && MFLAG="-mount"

# SVR3 and friends - slow
[ `ls -ilds $TMP.f 2> /dev/null | wc -w` -eq 11 ] && \
    LFLAG="-exec ls -ilds {} ;"
# 4.0 BSD and friends - slow
[ `ls -gilds $TMP.f 2> /dev/null | wc -w` -eq 11 ] && \
    LFLAG="-exec ls -gilds {} ;"
# 4.3 BSD and friends - fast
find $TMP.f -type f -ls > /dev/null 2>&1 && \
    LFLAG="-ls"

rm $TMP.f

if [ -z "$MFLAG" -o -z "$LFLAG" ]; then
    echo "find does not support -mount or -ls!"
    exit
fi

# Search each disk recording file sizes
# ignoring repeat hard links and holey files

for i in $NUMS; do
    d=`echo $DISKS | awk '{print $'$i'}'`
    m=`echo $MPTS | awk '{print $'$i'}'`
    echo "Processing $d $m"
    echo "This may take a while.  Please wait ..."
    echo BEGIN_DATA > $TMP.$i
    find $m $MFLAG \( -type f -o -type d \) $LFLAG 2> /dev/null | \
        awk '{if ($2 * 1024 >= $7) print $7, $1}' | sort -n | uniq | \
        awk '{print $1}' | uniq -c | awk '{print $2, $1}' \
        >> $TMP.$i
    echo END_DATA >> $TMP.$i
    echo
done
echo 'Phew!  All done.  Results are in "'$TMP'.*"'

# Display a summary of the results

echo
echo "Summarizing results.  Please wait ..."

for i in $NUMS; do
    cat $TMP.$i
done | sort -n | awk '
BEGIN {
    p=1;
    for (i=0; i<32; i++) {
        pow2[i] = p;
        p = 2 * p;
    }
    s = 0;
}
/^[0-9]/ {
    size = $1;
    num = $2;
    while (size > pow2[s]) {
        s++;
    }
    count[s] += num;
}
END {
    for (i=0; i<32; i++) {
        if (count[i] > 0) {
            limit = i;
        }
    }
    for (i=0; i<=limit; i++) {
        files += count[i];
        space[i] = (pow2[i] + pow2[i-1]) / 2.0 * count[i];
        spaces += space[i];
    }
    if (spaces == 0) {
        print "No results!";
        exit 1;
    }
    print
    printf("%12s %12s %7s %12s %7s\n", \
           "file size", "#files", "%files", "disk space", "%space");
    printf("%12s %12s %7s %12s %7s\n", \
           "(max. bytes)", "", "", "(Mb)", "");
    for (i=0; i<=limit; i++) {
        printf("%12d %12d %7.1f %12.1f %7.1f\n", \
               pow2[i], count[i], 100.0 * count[i] / files, \
               space[i] / 1.0e6, 100.0 * space[i] / spaces);
    }
}' || exit

echo
echo 'File size data stored in "'$TMP'.*"'

exit
