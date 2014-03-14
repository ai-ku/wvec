#!/usr/bin/perl -w
#
# viterbitag.pl modelfile < segmentedwords
#
# <modelfile> is a file containing values for
# P(tag_i | tag_j) and P(morph_k | tag_i).
# <modelfile> can be produced using entrofix.pl.
#
# <segmentedwords> is a list of word segmentations including word counts.
# <segmentedwords> can be produced using autosplitwords_pg.pl.
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

$| = 1;
$traceon = 0;
$logprobzero = 1000;

# Read command line arguments

($me = $0) =~ s,^.*/,,;

$modelfile = shift @ARGV;
&usage() unless ($modelfile);

$starttime = time;

$maxtag = -1;
%tagids = ();
@tagnames = ();

$maxmorphid = 0;
%morphids = ();
$morphids{' '} = 0;	# Word boundary

# Read initial probabilities

print "# Reading initial probabilities from file \"$modelfile\"...\n";

open(MODEL, $modelfile) ||
    die "Error ($me): Unable to open file \"$modelfile\" for reading.\n";

while ($line = <MODEL>) {
    chomp $line;
    if ($line =~ /^P\(([^ ]+) \-> ([^\)]+)\) = ([\.0-9]+)/) {
	$tag1 = $1;
	$tag2 = $2;
	$p = $3;
	unless (defined $tagids{$tag1}) {
	    $maxtag++;
	    $tagids{$tag1} = $maxtag;
	    push @tagnames, $tag1;
	}
	unless (defined $tagids{$tag2}) {
	    $maxtag++;
	    $tagids{$tag2} = $maxtag;
	    push @tagnames, $tag2;
	}
	if ($p == 0) {
	    $logp = $logprobzero;
	}
	else {
	    $logp = -log($p);
	}
	$logptrans[$tagids{$tag1}][$tagids{$tag2}] = $logp;
    }
    elsif ($line =~ /^([^\#][^\t]*)\t(.+)/) {
	$morph = $1;
	@probs = split(/\t/, $2);
	$maxmorphid++;
	$morphids{$morph} = $maxmorphid;
	foreach $tag (0 .. $#probs) {
	    if ($probs[$tag] == 0) {
		$logp = $logprobzero;
	    }
	    else {
		$logp = -log($probs[$tag]);
	    }
	    # Note: The tag ids are here one less than in the
	    # transition probabilities!! It would not make sense
	    # to reserve $pmorphwhentag[x][0] = 0 for all x except word
	    # boundary:
	    $logpmorphwhentag[$maxmorphid][$tag] = $logp;
	}
	die "Assertion failed ($me): Tag number mismatch for morph " .
	    "\"$morph\".\n" unless (scalar(@probs) == $maxtag);
    }
}
close MODEL;

if ($traceon) {
    print "# Initial probabilities:\n";
    &reporttagbigramprobs(1);
    &reportmorphwhentagprobs(1);
}

# Read and tag the segmented words

while ($line = <>) {
    chomp $line;
    if ($line =~ /^([0-9]+) (.+)$/) {
	$wcount = $1;
	$segword = $2;
	$segword =~ s/ \+ / /g;
	@morphs = split(/ +/, $segword);
	@tags = &viterbitag(@morphs);
	foreach $i (0 .. $#morphs) {
	    $morphs[$i] .= '/' . $tagnames[$tags[$i]];
	}
	print "$wcount " . join(' + ', @morphs) . "\n";
    }
}

$totaltime = time - $starttime;
print "# Time used (secs): $totaltime\n";

# End.

# Tag the segmented words according to the given probs

sub viterbitag {
    my(@morphs) = @_;
    my($morph, $tag1, $tag2);

    # Delta is the lowest accumulated cost ending in each possible state
    my(@delta);
    # Psi is a table of back pointers that indicate the best path
    my(@psi) = ();

    # Initialize the first state
    foreach $tag1 (0 .. $maxtag) {
	# And pseudo-zero probs for the rest
	$delta[$tag1] = $logprobzero;
	$psi[0][$tag1] = 0;
    }
    $delta[0] = 0; # Probability of one that the first state is a word
	           # boundary

    my($morphid, $cost);
    my(@bestcost, @besttag);
    my($i) = 0;

    push @morphs, ' ';	# Add word break at the end
 
    # Viterbi left-to-right
    foreach $morph (@morphs) {
	$i++;
	$morphid = $morphids{$morph};
	$bestcost[0] = $logprobzero;
	$besttag[0] = 0;
	if ($morphid == 0) {
	    # End of word
	    foreach $tag1 (0 .. $maxtag) {
		$cost = $delta[$tag1] + $logptrans[$tag1][0];
		if ($cost <= $bestcost[0]) {
		    $bestcost[0] = $cost;
		    $besttag[0] = $tag1;
		}
	    }
	}
	else {
	    # For each next state ..
	    foreach $tag2 (1 .. $maxtag) {
		$bestcost[$tag2] = $logprobzero;
		# ... select the best previous state:
		foreach $tag1 (0 .. $maxtag) {
		    $cost = $delta[$tag1] + $logptrans[$tag1][$tag2]
			+ $logpmorphwhentag[$morphid][$tag2-1];
		    if ($cost <= $bestcost[$tag2]) {
			$bestcost[$tag2] = $cost;
			$besttag[$tag2] = $tag1;
		    }
		}
	    }
	}
	# Update delta and psi
	foreach $tag1 (0 .. $maxtag) {
	    $delta[$tag1] = $bestcost[$tag1];
	    $psi[$i][$tag1] = $besttag[$tag1];
	}
    }

    # Backtrace for the best tag sequence
    my(@tags) = ();
    $tag1 = 0;
    while ($i > 1) {
	$tag1 = $psi[$i][$tag1];
	$i--;
	unshift @tags, $tag1;
    }

    return @tags;
}

sub usage {
    die "Usage: $me modelfile < segmentedwords\n";
}
