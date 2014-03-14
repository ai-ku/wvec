#!/usr/bin/perl -w
#
# display_morph_counts.pl wordcountfile < morphsplits
#
# Reads a file with word and word counts and displays split words (read from
# another file) together with their word counts
#
# Copyright (C) 2002-2006 Mathias Creutz, Sami Virpioja
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

die "Usage: $me [-noerr] wordcountfile < morphsplits\n" unless (@ARGV > 0);

$noerr = 0;

while (@ARGV > 0) {
    $arg = shift @ARGV;
    if ($arg eq "-noerr") {
	$noerr = 1;
    }
    else {
	$wcfile = $arg;
    }
}

# Read word list

open(WCFILE, $wcfile) ||
    die "Error ($me): Unable to open file \"$wcfile\" for reading.\n";
while ($line = <WCFILE>) {
    chomp $line;
    ($wcount, $word) = split(' ', $line);
    $wordcount{$word} = $wcount;
}
close WCFILE;

# Read analysis file

$nsuperfluous = 0;

while ($line = <>) {
    chomp $line;
    next if ($line =~ /^\s*$/);
    if ($line =~ /^\#/) {
	print "$line\n";
	next;
    }
    $line =~ s/ \+ / /g;
    @morphs = split(' ', $line);
    ($word = $line) =~ s,/[^ ]+,,g; 	# Remove category labels
    $word =~ tr/ //d;
    if (defined($wordcount{$word})) {
	$wcount = $wordcount{$word};
	delete $wordcount{$word};	# Already saw this word
    }
    else {
	print STDERR
	    "Warning ($me): Analysis for word \"$word\" is superfluous.\n"
	    unless ($noerr);
	$nsuperfluous++;
	next;
    }
    print "$wcount ", join(' + ', @morphs) . "\n";
}

# If an analysis for some word was missing, output an error message
# (not when the -noerr option is in use)

$exitcode = 0;
$nmissingwords = 0;

foreach $word (keys %wordcount) {
    unless ($noerr) {
	$exitcode = -1;
	print STDERR "Error ($me): No analysis defined for word \"$word\".\n";
    }
    $nmissingwords++;
}

print STDERR "There were $nsuperfluous superfluous words.\n"
    if ($nsuperfluous);
print STDERR "There were $nmissingwords words with no analysis.\n"
    if ($nmissingwords);

exit($exitcode);
