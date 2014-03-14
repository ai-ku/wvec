#!/usr/bin/perl -w
#
# estimateprobs.pl [-pplthresh float] [-pplslope float]
#                  [-lenthresh float] [-lenslope float]
#                  [-wtypeppl | -wtokenppl] [-subppl | -nosubppl]
#                  [-minppllen int] < morph_segmentation
#
# morph_segmentation may contain tags for the morphs. If so, transition
# probabilities are estimated from the tagging. Otherwise, a unigram
# distribution for the transitions is output (as initial values), where
# the probability of the transition equals the unigram probability of the
# destination class.
#
# morph_segmentation contains lines of the format:
# <wordcount>  <morph1>/<tag1> <morph2>/<tag2> <morph3>/<tag3> ...
#   where the slashes and the tags may be missing. If there are tags,
#   the morph can end in an asterisk (*) plus a number 0 - 4. If the
#   number is within the range 1 - 4, the morph has a substructure
#   particular to a certain type of context: (1) word initial,
#   (2) word final, (3) word-initial-final, (4) and word-center. If the
#   number is 0, the morph has no substructure in that context, but
#   the same morph string *does* have a substructure in some other context
#   (1 - 4). That is "talo*0" simply means that there also exists "talo*1",
#   "talo*2", "talo*3", or "talo*4", whereas "talo" means that this morph
#   string does not have a substructure in any context.
#
# morph_segmentation also contains lines of the following format, but
# only if there are tags:
# 1 <contexttype> <morph1>/<tag1> <morph2>/<tag2>
#   This is the recursive structure of the string <morph1>+<morph2> with
#   the context type <contexttype>. <contexttype> consists of an asterisk
#   and a number 1-4 (see above).
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

# Parameters

$pplthresh = 100;     # Threshold perplexity, above which prefix and
		      # suffix are probable
$pplslope = -1;	      # Slope of perplexity sigmoid (only temporary value!)
		      # (higher value => steeper step)
$lenthresh = 3;       # Length threshold, above which stems are probable
$lenslope = 2;        # Slope of length sigmoid
$usewordtypeppl = 1;  # Whether to use word counts when computing predecessor
		      # and successor perplexities 
$computesubppl = 0;   # Whether to compute perplexities for the morph
		      # occurrences within the sub-structures
$minppllen = 4;	      # Morphs shorter than this value are excluded when the
		      # context of a morph is collected (in order to compute
		      # left and right perplexity).

# Constants
$| = 1;		      # Flush output

# Read command line arguments

($me = $0) =~ s,^.*/,,;

while ($arg = shift @ARGV) {
    if ($arg eq '-pplthresh') {
	$pplthresh = shift @ARGV;
	&usage() unless ($pplthresh =~ m/^[\.0-9]+$/);
    }
    elsif ($arg eq '-pplslope') {
	$pplslope = shift @ARGV;
	&usage() unless ($pplslope =~ m/^[\.0-9]+$/);
    }
    elsif ($arg eq '-lenthresh') {
	$lenthresh = shift @ARGV;
	&usage() unless ($lenthresh =~ m/^[\.0-9]+$/);
    }
    elsif ($arg eq '-lenslope') {
	$lenslope = shift @ARGV;
	&usage() unless ($lenslope =~ m/^[\.0-9]+$/);
    }
    elsif ($arg eq '-wtypeppl') {
	$usewordtypeppl = 1;
    }
    elsif ($arg eq '-wtokenppl') {
	$usewordtypeppl = 0;
    }
    elsif ($arg eq '-subppl') {
	$computesubppl = 1;
    }
    elsif ($arg eq '-nosubppl') {
	$computesubppl = 0;
    }
    elsif ($arg eq '-minppllen') {
	$minppllen = shift @ARGV;
	&usage() unless ($minppllen =~ m/^[0-9]+$/);
    }
    else {
	&usage();
    }
}

$pplslope = 10/$pplthresh if ($pplslope < 0);

$starttime = time;

print "# $me, " . localtime() . "\n";
print "# -pplthresh $pplthresh\n";
print "# -pplslope $pplslope\n";
print "# -lenthresh $lenthresh\n";
print "# -lenslope $lenslope\n";
if ($usewordtypeppl) {
    print "# -wtypeppl: yes\n";
}
else {
    print "# -wtypeppl: no (-wtokenppl)\n";
}
if ($computesubppl) {
    print "# -subppl: yes\n";
}
else {
    print "# -subppl: no (-nosubppl)\n";
}
print "# -minppllen $minppllen\n";

@tagset = ('#', 'PRE', 'STM', 'SUF', 'ZZZ');

foreach $tag1 (@tagset) {
    $ntokenstagged{$tag1} = 0;
    foreach $tag2 (@tagset) {
	$ntransitions{$tag1}{$tag2} = 0;
    }
}

# Variables

$nwords = 0;	  # Number of word tokens
$lastmorph = 0;   # Ordinal number of last morph read so far
		  # (including word breaks)
$morphids[0] = 0; # Numeral ID of the ith morph
$counts[0] = 0;	  # Count of the ith morph (equals word count of the word the
		  # morph occurs in)

# Read the morpheme segmentation file and build a data structure
# of the corpus. Every morph gets a slot with its count and another slot
# with the morph ID. Also count the number of transitions between tags.
#
while ($line = <>) {
    chomp $line;
    if ($line =~ m/^([0-9]+) (.+)$/) {
	$wcount = $1;
	$analysis = $2;
	$analysis =~ tr/\+//d;
	@morphs = split(/ +/, $analysis);
	if ($morphs[0] =~ m/^\*[1-4]$/) {
	    # It's the contents of a substructure
	    $issubstructure = 1;
	    $contexttype = shift @morphs;
	    $prevtag = "";	# There is no predecessor morph
	    $supermorph = "";
	    $submorphstr = "";
	}
	else {
	    $issubstructure = 0;
	    $prevtag = "#";	# The predecessor morph is the word boundary
	}
	foreach $morph (@morphs) {
	    if ($morph =~ m,^([^/]+)/([^/]+)$,) {
		# There is a morph and a tag
		$morph = $1;
		$tag = $2;
		if ($prevtag) {
		    # Add to transition counters
		    $ntokenstagged{$prevtag} += $wcount;
		    $ntransitions{$prevtag}{$tag} += $wcount;
		}
		$prevtag = $tag;
		if ($issubstructure) {
		    # Build the upper-level morph string and the tag
		    # sequence
		    $supermorph .= &deasterisk($morph);
		    $submorphstr .= " $morph $tag";
		    $submorphstr =~ s/^ //;
		}
	    }
	    if (!($issubstructure) || ($computesubppl)) {
		$lastmorph++;
		# Locations of context-specific morphs
		push @{$locations{$morph}}, $lastmorph;
		$noasterisk = &deasterisk($morph);
		if ($noasterisk ne $morph) {
		    # The morph has different representations in different
		    # contexts. Store context-independent locations as well
		    # (for the perplexity calculations). The context-
		    # independent variant is here rendered as a string that
		    # terminates in "*" but there is no number after the
		    # asterisk.
		    push @{$locations{$noasterisk . "*"}}, $lastmorph;
		}
		$counts[$lastmorph] = $wcount;
	    }
	    $freqs{$morph} += $wcount;
	}
	if ($issubstructure) {
	    # Store the tag sequence that the upper-level morph
	    # consists of
	    $submorphs{$supermorph . $contexttype} = $submorphstr;
	}
	else {
	    $nwords += $wcount;
	    if ($prevtag ne "#") {
		# Add transition to word break (if there are tags)
		$ntokenstagged{$prevtag} += $wcount;
		$ntransitions{$prevtag}{"#"} += $wcount;
	    }
	}
	if (!($issubstructure) || ($computesubppl)) {
	    $lastmorph++;
	    # Word boundary morph (used both for words and substructs)
	    $morphids[$lastmorph] = 0; # Word boundary "morph"
	    $counts[$lastmorph] = $wcount;
	}
    }
}

$nmorphtypes = 0; # Number of different morph types (excluding word break)

# Fill in the morph IDs in the corpus data structure
while (($morph, $locs) = each %locations) {
    # Use only context-independent ID:s, because the perplexities
    # are based on them:
    unless ($morph =~ m/\*[0-4]$/) {
	$nmorphtypes++;
	foreach $i (@$locs) {
	    if (length(&deasterisk($morph)) < $minppllen) {
		$morphids[$i] = -1;	# Mark that short morphs are
	    }				# to be ignored
	    else {
		$morphids[$i] = $nmorphtypes;
	    }
	}
    }
}

# For each morph, compute left and right perplexity, and morph length.
# Based on these features in combination with possible substructure tags,
# the prior probabilities P(tag_i | morph_i) are then computed.
# 

print "# Prior distribution for P(Tag | morph)\n";

foreach $morph (sort {length($a) <=> length($b)} keys %freqs) {
    # Shortest morphs first, so that probabilities already exist for
    # submorphs of longer morphs.
    ($morphstr = $morph) =~ s/\*[0-4]$/\*/;	# Context-independent variant
    $locs = $locations{$morphstr};
    if (defined $locs) {
	%left = ();
	%right = ();
	$nlefttok = 0;
	$nrighttok = 0;
	foreach $i (@$locs) {
	    if ($usewordtypeppl) {
		$count = 1;
	    }
	    else { 
		$count = $counts[$i];
	    }
	    
	    $leftid = $morphids[$i-1];
	    unless ($leftid == -1) {	# Too short morph
		$left{$leftid} += $count;
		$nlefttok += $count;
	    }

	    $rightid = $morphids[$i+1];
	    unless ($rightid == -1) {	# Too short morph
		$right{$rightid} += $count;
		$nrighttok += $count;
	    }
	}

	$entr = 0;
	foreach $l (keys %left) {
	    $p = $left{$l}/$nlefttok;
	    $entr -= $p*log($p);
	}
	$lperp = exp($entr);
	
	$entr = 0;
	foreach $r (keys %right) {
	    $p = $right{$r}/$nrighttok;
	    $entr -= $p*log($p);
	}
	$rperp = exp($entr);
    }
    else {	# The morph exists only in sub-structures and
		# they are not included
	$lperp = 1;
	$rperp = 1;
    }

    $len = length(&deasterisk($morph));

    printf("#Features(\"%s\")\t%.4f\t%.4f\t%d\n",
	   $morph, $rperp, $lperp, $len);

    $prelike = 1/(1 + exp(-$pplslope*($rperp - $pplthresh)));
    $suflike = 1/(1 + exp(-$pplslope*($lperp - $pplthresh)));
    $stmlike = 1/(1 + exp(-$lenslope*($len - $lenthresh)));

    $pnomo = (1 - $prelike)*(1 - $suflike)*(1 - $stmlike);
    if ($pnomo == 1) {
	$ppre = 0;
	$psuf = 0;
	$pstm = 0;
    }
    else {
	$pnomo = 0.001 if ($pnomo < 0.001);
	$normcoeff =
	    (1 - $pnomo)/(($prelike**2) + ($suflike**2) + ($stmlike**2));
	$ppre = ($prelike**2)*$normcoeff;
	$psuf = ($suflike**2)*$normcoeff;
	$pstm = 1 - $ppre - $psuf - $pnomo;
    }

    $submorphstr = $submorphs{$morph};
    if (defined $submorphstr) {
	# This morph has substructure. This may put constraints on
	# the tag of the morph.
	($morph1, $tag1, $morph2, $tag2) = split(m/ /, $submorphstr);
	if (($tag1 eq "PRE") && ($tag2 eq "PRE")) {
	    # The morph consists of two prefixes and can thus be treated
	    # as a prefix. Use prefix probability of either submorph, so
	    # that the submorph with lower prefix probability is chosen.
	    $ppre = $ppres{$morph1};
	    die "$me: Assertion failed: Undefined probs for morph " .
		"\"$morph1\".\n" unless (defined $ppre);
	    $tmp = $ppres{$morph2};
	    die "$me: Assertion failed: Undefined probs for morph " .
		"\"$morph2\".\n" unless (defined $tmp);
	    $ppre = $tmp if ($tmp < $ppre);
	    $psuf = 0;	# Cannot be suffix
	    $pstm = 0;	# or stem
	    $pnomo = 1 - $ppre if ($pnomo > 1 - $ppre);	# Total prob max = 1
	}
	elsif (($tag1 eq "SUF") && ($tag2 eq "SUF")) {
	    # The morph consists of two suffixes and can thus be treated
	    # as a suffix. Use suffix probability of either submorph, so
	    # that the submorph with lower suffix probability is chosen.
	    $psuf = $psufs{$morph1};
	    die "$me: Assertion failed: Undefined probs for morph " .
		"\"$morph1\".\n" unless (defined $psuf);
	    $tmp = $psufs{$morph2};
	    die "$me: Assertion failed: Undefined probs for morph " .
		"\"$morph2\".\n" unless (defined $tmp);
	    $psuf = $tmp if ($tmp < $psuf);
	    $ppre = 0;	# Cannot be prefix
	    $pstm = 0;	# or stem.
	    $pnomo = 1 - $psuf if ($pnomo > 1 - $psuf);	# Total prob max = 1
	}
	elsif (($tag1 ne "ZZZ") && ($tag2 ne "ZZZ")) {
	    # Don't allow prefixes and suffixes unless either submorph
	    # is a non-morpheme. If either submorph is a non-morpheme
	    # the morph will work as an entity of its own, and no probs
	    # need to be adjusted.
	    $ppre = 0;
	    $psuf = 0;
	}
    }

    printf("#P(Tag|\"%s\")\t%.10f\t%.10f\t%.10f\t%.10f\n",
	   $morph, $ppre, $pstm, $psuf, $pnomo);

    $ppres{$morph} = $ppre;
    $psufs{$morph} = $psuf;
    $pstms{$morph} = $pstm;
    $pnomos{$morph} = $pnomo;
    
    # Accumulate for class probs
    $nclass{"PRE"} += $ppre*$freqs{$morph};
    $nclass{"SUF"} += $psuf*$freqs{$morph};
    $nclass{"STM"} += $pstm*$freqs{$morph};
    $nclass{"ZZZ"} += $pnomo*$freqs{$morph};
}

# Output class probabilities

$nmorphtokens =
    $nclass{"PRE"} + $nclass{"STM"} + $nclass{"SUF"} + $nclass{"ZZZ"};
printf("#PTag(\"PRE\")\t%.10f\n", $nclass{"PRE"}/$nmorphtokens);
printf("#PTag(\"STM\")\t%.10f\n", $nclass{"STM"}/$nmorphtokens);
printf("#PTag(\"SUF\")\t%.10f\n", $nclass{"SUF"}/$nmorphtokens);
printf("#PTag(\"ZZZ\")\t%.10f\n", $nclass{"ZZZ"}/$nmorphtokens);

# Compute and output transition probabilities
#

if ($ntokenstagged{"#"} == 0) {
    # There have been no tags and therefore the transition accumulators
    # equal zero. Fill them with a unigram distribution (= each tag is
    # presumed to be succeeded by the expectation over all data of the
    # number of prefixes, suffixes, stems, non-morphemes and word breaks).
    $nclass{"#"} = $nwords;
    foreach $tag1 (@tagset) {
	foreach $tag2 (@tagset) {
	    next if (($tag1 eq "#") && ($tag2 eq "#"));
	    $ntransitions{$tag1}{$tag2} = $nclass{$tag2};
	    $ntokenstagged{$tag1} += $nclass{$tag2};
	}
    }
}

foreach $tag1 (@tagset) {
    foreach $tag2 (@tagset) {
	next if (($tag1 eq "#") && ($tag2 eq "#"));
	if ((($tag1 eq "PRE") && ($tag2 eq "#")) ||
	    (($tag1 eq "PRE") && ($tag2 eq "SUF")) ||
	    (($tag1 eq "#") && ($tag2 eq "SUF"))) {
	    # Zero transitions by default: Make them zero if they
	    # aren't already (for some reason)
	    $count = $ntransitions{$tag1}{$tag2};
	    $ntokenstagged{$tag1} -= $count;
	    $ntransitions{$tag1}{$tag2} = 0;
	}
    }
}

# Output transition probs P(tag_j | tag_i)
foreach $tag1 (@tagset) {
    foreach $tag2 (@tagset) {
	$n = $ntransitions{$tag1}{$tag2};
	$nall = $ntokenstagged{$tag1};
	if ($nall > 0) {
	    printf("P(%s -> %s) = %.10f (N = %d)\n",
		   $tag1, $tag2, $n/$nall, $n);
	}
	else {
	    printf("P(%s -> %s) = %.10f (N = %d)\n", $tag1, $tag2, 0, 0);
	}
    }
}

# Compute and output a posteriori morph emission probs P(morph_i | tag_i)
#

foreach $morph (keys %locations) {
    next if ($morph =~ m/\*$/);	# This is the context-independent version
				# and is no real morph
    printf("%s\t%.10f\t%.10f\t%.10f\t%.10f\n", $morph,
	   $ppres{$morph}*$freqs{$morph}/$nclass{"PRE"},
	   $pstms{$morph}*$freqs{$morph}/$nclass{"STM"},
	   $psufs{$morph}*$freqs{$morph}/$nclass{"SUF"},
	   $pnomos{$morph}*$freqs{$morph}/$nclass{"ZZZ"});

}

$totaltime = time - $starttime;
print "# Time used (secs): $totaltime\n";

# End.

sub deasterisk {
    my($morph) = shift @_;
    $morph =~ s/\*[0-4]?$//;	# Remove asterisk and number at the end
    return $morph;
}

sub usage {
    die "Usage: $me [-pplthresh float] [-pplslope float] [-lenthresh float]" .
	" [-lenslope float] [-wtypeppl | -wtokenppl] [-subppl | -nosubppl]" .
	" [-minppllen int] < morph_segmentation\n";

}
