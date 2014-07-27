#!/usr/bin/perl -w

$l = "";
while(<>) {
    chop;
    if (not m/\S/) {
        print "$l\n";
        $l = "";
    } else {
        die $! if m/\|/;
        s/ /\|/g;
        $l .= "$_ ";
    }
}
