#!/usr/bin/perl -w
#
# viterbitagsplit.pl -probs probsfile [-cutoff int] < wordlist
#
# 'probsfile' contains probabilities P(tag_j | tag_i) and
# P(morph_k | tag_j).
#
# 'cutoff' is a threshold value. For each tagged morph in 'probsfile',
# the number of occurrences of this morph in the tagged file from which
# 'probsfile' was produced is calculated. If this value falls below the
# cutoff value, the probability of this tagged morph is set to zero.
# This means that this tagged morph is entirely "forgotten" by this script.
#
# 'wordlist' contains one word per line preceded by a word count. Every
# word in 'wordlist' will be segmented and tagged by this script.
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

$logprobzero = 1000; 
$probsfile = '';
$cutoff = 0.00000000001;
$| = 1;

# Read command line arguments

($me = $0) =~ s,^.*/,,;

while ($arg = shift @ARGV) {
    if ($arg eq "-probs") {
	$probsfile = shift @ARGV;
	&usage() unless ($probsfile);
    }
    elsif ($arg eq "-cutoff") {
	$cutoff = shift @ARGV;
	&usage() unless ($cutoff =~ m/^[0-9]+$/);
    }
    else {
	&usage();
    }
}

&usage() unless ($probsfile);

$starttime = time;

print "# $me, " . localtime() . "\n";
print "# -probs \"$probsfile\"\n";
print "# -cutoff $cutoff\n";

# Read initial probabilities

print "# Reading probabilities from file \"$probsfile\"...\n";

$maxtag = -1;
%tagids = ();
@tagnames = ();
@ntagged = ();

$maxmorphid = 0;
%morphids = ();

open(PROBS, $probsfile) ||
    die "Error ($me): Unable to open file \"$probsfile\" for reading.\n";

while ($line = <PROBS>) {
    chomp $line;
    if ($line =~ /^P\(([^ ]+) \-> ([^\)]+)\) = ([\.0-9]+) \(N = ([0-9]+)/) {
	$tag1 = $1;
	$tag2 = $2;
	$p = $3;
	$n = $4;
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
	$ntagged[$tagids{$tag1}] += $n;
    }
    elsif ($line =~ /^([^\#][^\t]*)\t(.+)/) {
	$morph = $1;
	@probs = split(/\t/, $2);
	$maxmorphid++;
	$morphids{$morph} = $maxmorphid;
	foreach $i (0 .. $#probs) {
	    $noccs = $ntagged[$i+1]*$probs[$i];
	    if ($noccs < $cutoff) {
		$logp = $logprobzero;
	    }
	    else {
		$logp = -log($probs[$i]);
	    }
	    # Note: The tag ids are here one less than in the
	    # transition probabilities!! It would not make sense
	    # to reserve $logpmorphwhentag[x][0] = 0 for all x except
	    # word boundary:
	    $logpmorphwhentag[$maxmorphid][$i] = $logp;
	}
	die "Assertion failed ($me): Tag number mismatch for morph " .
	    "\"$morph\".\n" unless (scalar(@probs) == $maxtag);
    }
}
close PROBS;

# Segment (and tag) the words

while ($line = <>) {
    chomp $line;
    if ($line =~ /^([0-9]+) (.+)$/) {
	$wcount = $1;
	$word = $2;
	@morphs = &viterbisplit($word);
	print "$wcount " . join(' + ', @morphs) . "\n";
    }
}

$totaltime = time - $starttime;
print "# Time used (secs): $totaltime\n";

# End.

sub viterbisplit {
    my($word) = @_;

    my($wlen) = length($word);

    # Delta is the lowest accumulated cost ending in each possible
    # tag/morph combination. Delta is 3-dimensional:
    # $delta[POSITION][MORPHLEN][TAGID]
    my(@delta);

    # Psi is a table of back pointers that indicate the best path.
    # Psi consists of @psi_prevlen, @psi_prevtag and @psi_asterisk and
    # they are 3D: e.g.,
    # $psi_prevlen[POSITION_IN_WORD]
    #             [MORPHLEN_OF_MORPH_ENDING_AT_POSITION]
    #             [TAGID_OF_MORPH_ENDING_AT_POSITION]
    my(@psi_prevlen) = ();
    my(@psi_prevtag) = ();
    my(@psi_asterisk) = ();

    my($pos, $len, $tag, $prevlen, $prevtag);
    my($morphnoasterisk, $morph, $morphid, $tail);
    my($logpmorph, $bestcost, $cost);
    my($bestprevlen, $bestprevtag, $bestasterisk, $bestlen, $besttag);
    my(@morphs);

    # Viterbi segmentation
    foreach $pos (1 .. $wlen) {
      L_LOOP:
	foreach $len (1 .. $pos) {
	    $prevpos = $pos - $len;

	    # Collect all context-dependent variants for a morph
	    # corresponding to this substring of the word
	    $morphnoasterisk = substr($word, $prevpos, $len);
	    @morphs = ();
	    foreach $tail ("", "*0", "*1", "*1", "*2", "*3", "*4") {
		$morph = $morphnoasterisk . $tail;
		push @morphs, $morph if (defined $morphids{$morph});
	    }
	    unless (@morphs) {
		# There is no morph that corresponds to this substring
		# of the word: Store zero probability and continue.
		foreach $tag (1 .. $maxtag) {
		    $delta[$pos][$len][$tag] = $logprobzero;
		    $psi_prevlen[$pos][$len][$tag] = 0;
		    $psi_prevtag[$pos][$len][$tag] = 0;
		    $psi_asterisk[$pos][$len][$tag] = "";
		}
		next L_LOOP;
	    }

	    foreach $tag (1 .. $maxtag) {

		# Find the best previous morph/tag combination
		# for the current morph/tag combination:
		#
		$bestcost = $logprobzero;
		foreach $morph (@morphs) {
		    $morphid = $morphids{$morph};
		    # Find out probability of current morph/tag combination
		    # P(morph_i | tag_i):
		    #
		    $logpmorph = $logpmorphwhentag[$morphid][$tag-1];
		    if ($prevpos == 0) { # First morph in word
			# Add cost of transition: P(tag_i | #)
			$cost = $logptrans[0][$tag] + $logpmorph;
			if ($cost <= $bestcost) {
			    $bestcost = $cost;
			    $bestprevlen = 0;
			    $bestprevtag = 0;
			    $bestasterisk = $morph;
			}
		    }
		    else { # Preceded by other morphs
			foreach $prevlen (1 .. $prevpos) {
			    foreach $prevtag (1 .. $maxtag) {
				# Add cost of transition: P(tag_i | tag_j)
				$cost = $delta[$prevpos][$prevlen][$prevtag]
				    + $logptrans[$prevtag][$tag] + $logpmorph;
				if ($cost <= $bestcost) {
				    $bestcost = $cost;
				    $bestprevlen = $prevlen;
				    $bestprevtag = $prevtag;
				    $bestasterisk = $morph;
				}
			    }
			}
		    }
		}

		# Store info about best path to the current state
		$delta[$pos][$len][$tag] = $bestcost;
		$psi_prevlen[$pos][$len][$tag] = $bestprevlen;
		$psi_prevtag[$pos][$len][$tag] = $bestprevtag;
		$psi_asterisk[$pos][$len][$tag] = $bestasterisk;

	    }
	}	
    }

    # Find the best transition to the final word boundary
    $bestcost = $logprobzero;
    foreach $len (1 .. $wlen) {
	foreach $tag (1 .. $maxtag) {
	    # Add cost of transition: P(# | tag_j)
	    $cost = $delta[$wlen][$len][$tag] + $logptrans[$tag][0];
	    if ($cost <= $bestcost) {
		$bestcost = $cost;
		$bestlen = $len;
		$besttag = $tag;
	    }
	}
    }

    if ($bestcost == $logprobzero) {
	print STDERR
	    "# WARNING: No possible segmentation for word \"$word\"\n";
	return ($word);
    }

    # Trace back
    @morphs = ();
    $pos = $wlen;
    while ($pos) {
	$morph =
	    $psi_asterisk[$pos][$bestlen][$besttag];
	unshift @morphs, $morph . "/" . $tagnames[$besttag];
	$bestprevlen = $psi_prevlen[$pos][$bestlen][$besttag];
	$bestprevtag = $psi_prevtag[$pos][$bestlen][$besttag];
	$pos -= $bestlen;
	$bestlen = $bestprevlen;
	$besttag = $bestprevtag;
    }
    return @morphs;
}

sub usage {
    die "$me -probs probsfile [-cutoff int] < wordlist\n";
}
