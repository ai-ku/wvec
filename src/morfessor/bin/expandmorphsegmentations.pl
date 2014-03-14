#!/usr/bin/perl -w
#
# expandmorphsegmentations.pl [-full] [-showstruct] segmentation
#
# Expands the substructures of the morphs in every analyzed word to the lowest
# level that does not contain non-morphemes. However, if the segmentation
# does not contain any tags or the -full option is used, a full expansion
# is produced. The -showstruct option produces output, where there are
# parentheses showing the recursive structure.
#

# Copyright (C) 2002-2006 Mathias Creutz
#
# All software supplied with this package is released under the GNU
# General Public License.  This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation; either
# version 2, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License (below or at http://www.gnu.org/licenses/
# gpl.html) for more details.

($me = $0) =~ s,^.*/,,;

$fullexpand = 0;
$showstruct = 0;

while ($arg = shift @ARGV) {
    if ($arg eq "-full") {
	$fullexpand = 1;
    }
    elsif ($arg eq "-showstruct") {
	$showstruct = 1;
    }
    else {
	$analysisfile = $arg;
    }
}

&usage() unless ($analysisfile);

print "# $me, " . localtime() . "\n";
print "# Working dir: " . `pwd`;
print "# Input file: $analysisfile\n";
if ($fullexpand) {
    print "# -full: ON\n";
}
else {
    print "# -full: OFF\n";
}
if ($showstruct) {
    print "# -showstruct: ON\n";
}
else {
    print "# -showstruct: OFF\n";
}

$starttime = time;

# Read contents of substructures

open(ANAL, $analysisfile) ||
    die "Error ($me): Unable to open file \"$analysisfile\" for reading.\n";
while ($line = <ANAL>) {
    chomp $line;
    if ($line =~ m,^1 (\*[1-4]?) (.+)$,) {
	$ctxttype = $1;
	$seg = $2;
	$seg =~ s/ \+ / /g;
	@morphs = split(m/ +/, $seg);
	$supermorph = "";
	foreach $morphandtag (@morphs) {
	    ($morph = $morphandtag) =~ s,/.+$,,;
	    $supermorph .= &deasterisk($morph);
	}
	push @{$submorphs{$supermorph . $ctxttype}}, @morphs;
    }
}
close ANAL;

# Read segmentations and output expansion

open(ANAL, $analysisfile) ||
    die "Error ($me): Unable to open file \"$analysisfile\" for reading.\n";
while ($line = <ANAL>) {
    chomp $line;
    if ($line =~ m/^[0-9]+ [^\*]/) {
	$line =~ s/ \+ / /g;
	($wcount, @morphs) = split(m/ +/, $line);
	print "$wcount ";
	@morphsout = ();
	foreach $morph (@morphs) {
	    push @morphsout, &expand($morph);
	}
	if ($showstruct) {
	    print join(" ", @morphsout) . "\n";
	}
	else {
	    print join(" + ", @morphsout) . "\n";
	}
    }
}
close ANAL;

$totaltime = time - $starttime;

print "# Time used (secs): $totaltime\n";

# End.

sub expand {
    my($morphandtag) = shift @_;
    my($morph) = $morphandtag;
    $morph =~ s,/.+$,,;

    if ((defined $submorphs{$morph}) && !($morphandtag =~ m,/ZZZ$,)) {
	my(@morphsandtags) = ();
	push @morphsandtags, "(" if ($showstruct);
	foreach $submorph (@{$submorphs{$morph}}) {
	    if (!($fullexpand) && ($submorph =~ m,/ZZZ$,)) {
		# Don't expand to non-morphemes
		$morphandtag =~ s,\*[0-4]?/,/,;
		return ($morphandtag);
	    }
	    push @morphsandtags, &expand($submorph);
	}
	if ($showstruct) {
	    my($tag) = $morphandtag;
	    $tag =~ s,^[^/]+/,,;
	    push @morphsandtags, ")/$tag";
	} 
	return @morphsandtags;
    }
    
    $morphandtag =~ s,\*[0-4]/,/,;
    return ($morphandtag);
}

sub deasterisk {
    my($morph) = shift @_;
    $morph =~ s/\*[0-4]?$//;	# Remove asterisk and number at the end
    return $morph;
}

sub usage {
    die "Usage: $me [-full] [-showstruct] segmentationfile\n";
}
