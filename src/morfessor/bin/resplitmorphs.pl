#!/usr/bin/perl -w
#
# resplitmorphs.pl [-pplthresh float] [-pplslope float]
#                  [-lenthresh float] [-lenslope float]
#                  [-maxchanges int]
#                  -probs probsfile -alphabet alphabetfile
#                  -segmentation morph_segmentation
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
$pplslope = -1;	      # Slope of perplexity sigmoid (temporary value!)
$lenthresh = 3;       # Length threshold, above which stems are probable
$lenslope = 2;        # Slope of length sigmoid
$maxchanges = 10000;  # The maximal number of morphs that get a new
		      # representation during this iteration
$probsfile = "";      # Probability file (output of estimateprobs.pl)
$alphabetfile = "";   # Probability distribution over alphabet
$segfile = "";	      # Morph segmentation file

# Constants
$| = 1;		      # Flush output
$logc = log(2.865);   # Constant in the universal prior
$log2 = log(2);	      # = -log(1/2)

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
    elsif ($arg eq "-maxchanges") {
	$maxchanges = shift @ARGV;
	&usage() unless ($maxchanges =~ m/^[0-9]+$/);
    }
    elsif ($arg eq "-probs") {
	$probsfile = shift @ARGV;
    }
    elsif ($arg eq "-alphabet") {
	$alphabetfile = shift @ARGV;
    }
    elsif ($arg eq "-segmentation") {
	$segfile = shift @ARGV;
    }
    else {
	&usage();
    }
}

$pplslope = 10/$pplthresh if ($pplslope < 0);

&usage() unless ($probsfile && $alphabetfile && $segfile);

$starttime = time;

print "# $me, " . localtime() . "\n";
print "# -pplthresh $pplthresh\n";
print "# -pplslope $pplslope\n";
print "# -lenthresh $lenthresh\n";
print "# -lenslope $lenslope\n";
print "# -maxchanges $maxchanges\n";
print "# -probs \"$probsfile\"\n";
print "# -alphabet \"$alphabetfile\"\n";
print "# -segmentation \"$segfile\"\n";

$maxtag = -1;
%tagids = ();
@tagset = ();

#$maxmorphid = 0;
#%morphids = ();
#$morphids{' '} = 0;	# Word boundary
#@morphnames[0] = ' ';   # -"-

# Read initial probabilities

$logprobzero = 1000000;

print "# Reading perplexities and transition probabilities from file \"$probsfile\"...\n";

open(PROBS, $probsfile) ||
    die "Error ($me): Unable to open file \"$probsfile\" for reading.\n";

while ($line = <PROBS>) {
    chomp $line;
    if ($line =~ /^P\(([^ ]+) \-> ([^\)]+)\) = ([\.0-9]+)/) {
	$tag1 = $1;
	$tag2 = $2;
	$p = $3;
	unless (defined $tagids{$tag1}) {
	    $maxtag++;
	    $tagids{$tag1} = $maxtag;
	    push @tagset, $tag1;
	}
	unless (defined $tagids{$tag2}) {
	    $maxtag++;
	    $tagids{$tag2} = $maxtag;
	    push @tagset, $tag2;
	}
	if ($p == 0) {
	    $logp = $logprobzero;
	}
	else {
	    $logp = -log($p);
	}
	$logptrans[$tagids{$tag1}][$tagids{$tag2}] = $logp;
    }
    elsif ($line =~ m/^\#PTag\(\"([^\"]+)\"\)\t([\.0-9]+)$/) {
	$tag = $1;
	$p = $2;
	if ($p == 0) {
	    $logp = $logprobzero;
	}
	else {
	    $logp = -log($p);
	}
	$logptag{$tag} = $logp;
    }
    elsif ($line =~ m/^\#Features\(\"(.+)\"\)\t([\.0-9]+)\t([\.0-9]+)/) {
	$morph = $1;
	$rperp = $2;
	$lperp = $3;
	$morph =~ s/\*0$//; # No asterisks for non-recursive morphs
	$rperps{$morph} = $rperp;
	$lperps{$morph} = $lperp;
    }
}

close PROBS;

print "# Reading letter logprobs from file \"$alphabetfile\"...\n";

$logpunknownletter = 0;

open(ALPHABET, $alphabetfile) ||
    die "Error ($me): Unable to open file \"$alphabetfile\" for reading.\n";

while ($line = <ALPHABET>) {
    chomp $line;
    if ($line =~ m/^(.)\t([\.0-9]+)$/) {
	$letter = $1;
	$log2prob = $2;
	$letterlogprob{$letter} = log(2)*$log2prob;
	$logpunknownletter = $log2prob if ($log2prob > $logpunknownletter); 
    }
    else {
	die "Error ($me): Invalid line in file \"$alphabetfile\".\n";
    }
}

close ALPHABET;

# The probability of an unknown letter is the squared probability of the
# rarest known letter
$logpunknownletter = 2*log(2)*$logpunknownletter;

$nmorphtokens = 0;# Number of morph tokens
$nmorphtypes = 0; # Number of unique morph strings
@freqs = ();

print "# Reading segmentations from file \"$segfile\"...\n";

open(SEGS, $segfile) ||
    die "Error ($me): Unable to open file \"$segfile\" for reading.\n";

while ($line = <SEGS>) {
    chomp $line;
    if ($line =~ /^([0-9]+) (.+)$/) {
	$wcount = $1;
	$segword = $2;
	$segword =~ tr/\+//d;
	@morphs = split(/ +/, $segword);
	if ($morphs[0] =~ m/^\*[1-4]$/) {
	    # It's the contents of a substructure.
	    $contexttype = shift @morphs;
	    ($morph1, $tag1) = split(m:/:, $morphs[0]);
	    ($morph2, $tag2) = split(m:/:, $morphs[1]);
	    $morph1 =~ s/\*0$//; # No asterisks for non-recursive morphs
	    $morph2 =~ s/\*0$//; # -"-
	    $submorphs{&deasterisk($morph1) . &deasterisk($morph2) .
			   $contexttype} = join(" ",  $morph1, $tagids{$tag1},
						$morph2, $tagids{$tag2});
	}

	# Collect info about morph unigrams
	foreach $morphandtag (@morphs) {
	    ($morph, $tag) = split(m:/:, $morphandtag);
	    $morph =~ s/\*0$//;		# No asterisks for non-recursive morphs
	    $morphid = $idsofmorphs{$morph};
	    unless (defined $morphid) {	# New morph type
		$nmorphtypes++;
		$morphid = $nmorphtypes;
		$idsofmorphs{$morph} = $morphid;
		foreach $tagid (0 .. $maxtag) {
		    # Initialize number of times morph has been tagged
		    # with every possible tag
		    $freqs[$morphid][$tagid] = 0;
		}
	    }
	    $nmorphtokens += $wcount;	# Total number of morphs
	    # Increase frequency of this morph being tagged with this tag:
	    $freqs[$morphid][$tagids{$tag}] += $wcount; 
	    # ... and the total number of occurrences of this morph:
	    $freqs[$morphid][0] += $wcount;
	}
    }
}

close SEGS;

$lastmorphid = $nmorphtypes;

print "# Sorting morphs in length order...\n";

@sortedmorphs =
    sort {length(&deasterisk($a)) <=> length(&deasterisk($b))}
    keys %idsofmorphs;

print "# Re-analyzing morphs...\n";

$nchanges = 0;
foreach $morph (@sortedmorphs) {
    last if ($nchanges == $maxchanges);
    &reanalyzemorph($morph);
}

# Collect a list of the morphs that need to get a *0 appended to their names,
# i.e., morphs that have no substructure in a particular context, but do
# have substructure in another context.
foreach $morph (keys %submorphs) {
    $morphstr = &deasterisk($morph);
    $morphid = $idsofmorphs{$morphstr};
    if ((defined $morphid) && ($freqs[$morphid][0] > 0)) {
	$zeromorphs{$morphstr} = 1;
    }
}

# Read the segmentation file and output the joined representations

print "# Reading segmentations from file \"$segfile\" and outputting " .
    "new segmentations...\n";

open(SEGS, $segfile) ||
    die "Error ($me): Unable to open file \"$segfile\" for reading.\n";

while ($line = <SEGS>) {
    chomp $line;
    if ($line =~ /^([0-9]+) (.+)$/) {
	$wcount = $1;
	$segword = $2;
	$segword =~ tr/\+//d;
	@morphs = split(/ +/, $segword);
	next if ($morphs[0] =~ m/^\*[1-4]$/);	# It's the contents of a
						# substructure
	print "$wcount ";
	@morphsout = ();

	foreach $morphandtag (@morphs) {
	    ($morph, $tag) = split(m:/:, $morphandtag);
	    $morph =~ s/\*0$//; # No asterisks (yet) for non-recursive morphs
	    $morph = &changed($morph);	# Follow chain of changes
	    $morph .= "*0" if (defined $zeromorphs{$morph});
	    push @morphsout, "$morph/$tag";
	}
	print join(" + ", @morphsout) . "\n";
    }
}

close SEGS;

foreach $morph (keys %submorphs) {
    ($tail = $morph) =~ s/^[^\*]+//;
    ($submorph1, $tagid1, $submorph2, $tagid2) =
	split(m/ /, $submorphs{$morph});
    $submorph1 = &changed($submorph1);	# Follow chain of changes
    $submorph2 = &changed($submorph2);	# -"-
    $submorph1 .= "*0" if (defined $zeromorphs{$submorph1});
    $submorph2 .= "*0" if (defined $zeromorphs{$submorph2});
    $tag1 = $tagset[$tagid1];
    $tag2 = $tagset[$tagid2];
    print "1 $tail $submorph1/$tag1 + $submorph2/$tag2\n";
}

$totaltime = time - $starttime;
print "# Time used (secs): $totaltime\n";
print "# Changes made: $nchanges\n";

# End.

sub reanalyzemorph {
    my($morph) = shift @_;
    my($morphid) = $idsofmorphs{$morph};

    my(@freqs0) = ();
    push @freqs0, @{$freqs[$morphid]}; # Frequencies of the morph: total
				       # frequency and frequency for every tag
    return if ($freqs0[0] == 0);

    my($morph0) = &deasterisk($morph);
    my($submorphs0) = $submorphs{$morph};
    if (defined $submorphs0) {
	# Follow chain of changes:
	my($m1, $t1, $m2, $t2) = split(m/ /, $submorphs0);
	$submorphs0 = join(" ", &changed($m1), $t1, &changed($m2), $t2);
    }

    # Remove current representation:
    $leavesubstruct = 1;	# global var.
    &removemorph($morph, $morphid, @freqs0);
    $leavesubstruct = 0;	# global var.

    my($rperp) = $rperps{$morph};
    my($lperp) = $lperps{$morph};

    # (1) Compute the cost of having this morph spelled out in the lexicon
    #
    # Prob. of morph pointers
#    print "## (1) Testing $morph0\n";
    my($mrpid) = $idsofmorphs{$morph0};
    unless ($mrpid) {	# New morph
	$mrpid = $lastmorphid + 1;
	@{$freqs[$mrpid]} = (0, 0, 0, 0, 0);
    }
    my($bestcost) = &addmorph($morph0, $mrpid, $rperp, $lperp, @freqs0);
    # Probs P(Tag | morph)
    my(@diffclassprobs) = 
	&computecostofclasses($morph0, $rperp, $lperp, \@freqs0);
    my($tagid);
    foreach $tagid (1 .. $maxtag) {
	$bestcost += $diffclassprobs[$tagid];
    }
    # Cost of letters in lexicon (if the morph is new)
    $bestcost += &addletters($morph0, 1) if ($freqs[$mrpid][0] == $freqs0[0]);
    # Cost of token / type distribution
    $bestcost += &frequencycost();
    # @bestsolution contains the name of the morph,
    # its submorphs and their tag IDs:
    my(@bestsolution) = ($morph0, "", 0, "", 0);
    # Cancel the changes made during this test
    &removemorph($morph0, $mrpid, @freqs0);
    
    # (2) Compute the costs of replacing this variant by another morph
    # variant for the same string (that has sub-structure)
    #
    my(@alternatives) = ();
    my($mrp) = $morph0 . "*1";
    $mrpid = $idsofmorphs{$mrp};
    push @alternatives, $mrp if ((defined $mrpid) && ($freqs[$mrpid][0]));
    $mrp = $morph0 . "*2";
    $mrpid = $idsofmorphs{$mrp};
    push @alternatives, $mrp if ((defined $mrpid) && ($freqs[$mrpid][0]));
    $mrp = $morph0 . "*3";
    $mrpid = $idsofmorphs{$mrp};
    push @alternatives, $mrp if ((defined $mrpid) && ($freqs[$mrpid][0]));
    $mrp = $morph0 . "*4";
    $mrpid = $idsofmorphs{$mrp};
    push @alternatives, $mrp if ((defined $mrpid) && ($freqs[$mrpid][0]));
    if (scalar(@alternatives) > 0) {
	# This morph *does* exist in some other context
	my($cost) = 0;
	my($freqcost) = 0;
	foreach $mrp (@alternatives) {
#	    print "## (2) Testing $mrp\n";
	    $mrpid = $idsofmorphs{$mrp};
	    my($rperp1) = $rperps{$mrp};
	    my($lperp1) = $lperps{$mrp};
	    # Prob. of morph pointers
	    $cost = &addmorph($mrp, $mrpid, $rperp1, $lperp1, @freqs0);
	    # Probs P(Tag | morph)
	    @diffclassprobs = 
		&computecostofclasses($mrp, $rperp1, $lperp1, \@freqs0);
	    foreach $tagid (1 .. $maxtag) {
		$cost += $diffclassprobs[$tagid];
	    }
	    # Cost of token / type distribution
	    $freqcost = &frequencycost() unless ($freqcost); # Same for all
	    if ($cost + $freqcost < $bestcost) {
		$bestcost = $cost + $freqcost;
		@bestsolution = ($mrp, "", 0, "", 0);
	    }
	    # Cancel the changes made during this test
	    &removemorph($mrp, $mrpid, @freqs0);
	}
    }

    # (3) Compute the costs of having some sub-structure for this morph
    #
    # First invent a name for the morph
    if ($morph ne $morph0) {
	$mrp = $morph;	# The morph already ends in an asterisk + a number
    }
    else { # The morph had no sub-structure, so try to find a number
	   # that is not already occupied
	if (scalar(@alternatives) == 4) { # Impossible: all occupied 
	    $mrp = "";
	}
	else {	# Pick the lowest number that is not occpied
	    $mrp = $morph0 . "*4";
	    my($i) = 1;
	    my($tmp);
	    foreach $tmp (@alternatives) {
		if (!($tmp =~ m/$i$/)) {
		    # If the i:th morph isn't numbered as i, this number
		    # is not in use: Take it!
		    $mrp = $morph0 . "*$i";
		    last;
		}
		$i++;
	    }
	}
    }

    if ($mrp) {	# A name for the morph was found
	$mrpid = $idsofmorphs{$mrp};
	unless ($mrpid) {	# New morph
	    $mrpid = $lastmorphid + 1;
	    @{$freqs[$mrpid]} = (0, 0, 0, 0, 0);
	}
	# Cost of morph pointers
	my($basecost) = &addmorph($mrp, $mrpid, $rperp, $lperp, @freqs0);
	my($i, $cost);
#	print "## (3) Testing $mrp.\n";
	foreach $i (1 .. length($morph0)-1) {
	    # Test every split in two parts of the morph
	    my($morph1) = substr($morph0, 0, $i);
	    my($morph2) = substr($morph0, $i);
	    # ... and all existing context-dependent variants of
	    # the substrings are included:
	    my(@morphs1) = ();
	    push @morphs1, $morph1 unless (&changeobstacles($morph1));
	    my($mrp1) = $morph1 . "*1";
	    my($mrpid1) = $idsofmorphs{$mrp1};
	    push @morphs1, $mrp1
		if ((defined $mrpid1) && ($freqs[$mrpid1][0]));
	    $mrp1 = $morph1 . "*2";
	    $mrpid1 = $idsofmorphs{$mrp1};
	    push @morphs1, $mrp1
		if ((defined $mrpid1) && ($freqs[$mrpid1][0]));
	    $mrp1 = $morph1 . "*3";
	    $mrpid1 = $idsofmorphs{$mrp1};
	    push @morphs1, $mrp1
		if ((defined $mrpid1) && ($freqs[$mrpid1][0]));
	    $mrp1 = $morph1 . "*4";
	    $mrpid1 = $idsofmorphs{$mrp1};
	    push @morphs1, $mrp1
		if ((defined $mrpid1) && ($freqs[$mrpid1][0]));
	    my(@morphs2) = ();
	    push @morphs2, $morph2 unless (&changeobstacles($morph2));
	    my($mrp2) = $morph2 . "*1";
	    my($mrpid2) = $idsofmorphs{$mrp2};
	    push @morphs2, $mrp2
		if ((defined $mrpid2) && ($freqs[$mrpid2][0]));
	    $mrp2 = $morph2 . "*2";
	    $mrpid2 = $idsofmorphs{$mrp2};
	    push @morphs2, $mrp2
		if ((defined $mrpid2) && ($freqs[$mrpid2][0]));
	    $mrp2 = $morph2 . "*3";
	    $mrpid2 = $idsofmorphs{$mrp2};
	    push @morphs2, $mrp2
		if ((defined $mrpid2) && ($freqs[$mrpid2][0]));
	    $mrp2 = $morph2 . "*4";
	    $mrpid2 = $idsofmorphs{$mrp2};
	    push @morphs2, $mrp2
		if ((defined $mrpid2) && ($freqs[$mrpid2][0]));
	    my($tagid1, $tagid2);
	    # Alternatives for the first submorph
	    foreach $mrp1 (@morphs1) {
		$mrpid1 = $idsofmorphs{$mrp1};
		unless ($mrpid1) {	# New morph
		    $mrpid1 = $lastmorphid + 2;
		    @{$freqs[$mrpid1]} = (0, 0, 0, 0, 0);
		}
		my($rperp1) = $rperps{$mrp1};
		my($lperp1);
		if (defined $rperp1) {
		    $lperp1 = $lperps{$mrp1};
		}
		else {
		    # Undefined perplexities: Assume that this submorph
		    # only exists as a submorph of the current morph, which
		    # yields:
		    $rperp1 = 1;
		    $lperp1 = 1; #$lperp;
		}
		my($ppre1, $pstm1, $psuf1, $pnomo1) = 
			&getclassprobs($mrp1, $rperp1, $lperp1);
		$ppres{$mrp1} = $ppre1;
		$pstms{$mrp1} = $pstm1;
		$psufs{$mrp1} = $psuf1;
		$pnomos{$mrp1} = $pnomo1;
		# One occurrence of every tag: (first list item is never used)
		my(@addonelist) = (0, 1, 1, 1, 1);
		my(@diffcostclasses1) = 
		    &computecostofclasses($mrp1, $rperp1, $lperp1,
					  \@addonelist); 
		# Alternatives for the second submorph
		foreach $mrp2 (@morphs2) {
		    $mrpid2 = $idsofmorphs{$mrp2};
		    unless ($mrpid2) {	# New morph
			$mrpid2 = $lastmorphid + 3;
			@{$freqs[$mrpid2]} = (0, 0, 0, 0, 0);
		    }
		    my($rperp2) = $rperps{$mrp2};
		    my($lperp2);
		    if (defined $rperp2) {
			$lperp2 = $lperps{$mrp2};
		    }
		    else {
			# Undefined perplexities: Assume that this submorph
			# only exists as a submorph of the current morph, 
			# which yields:
			$rperp2 = 1; # $rperp;
			$lperp2 = 1;
		    }
		    my($ppre2, $pstm2, $psuf2, $pnomo2) = 
			&getclassprobs($mrp2, $rperp2, $lperp2);
		    $ppres{$mrp2} = $ppre2;
		    $pstms{$mrp2} = $pstm2;
		    $psufs{$mrp2} = $psuf2;
		    $pnomos{$mrp2} = $pnomo2;
		    my(@diffcostclasses2) = 
			&computecostofclasses($mrp2, $rperp2, $lperp2,
					      \@addonelist);
		    # Test (almost) every tag combination for the submorphs
		    foreach $tagid1 (1 .. 4) {
			foreach $tagid2 (1 .. 4) {
			    # Subtags may not be PRE + SUF
			    next if (($tagid1 == 1) && ($tagid2 == 3));
			    # Subtags may not be SUF + PRE or SUF + STM
			    next if (($tagid1 == 3) &&
				     (($tagid2 == 1) || ($tagid2 == 2)));
			    # Subtags may not be STM + PRE
			    next if (($tagid1 == 2) && ($tagid2 == 1));
#			    print "## (3) Testing $mrp ($mrp1/$tagset[$tagid1]+$mrp2/$tagset[$tagid2])\n";
			    $cost = $basecost;
			    # Pointer and emission cost of submorph1
			    my(@deltafreqs1) = (1, 0, 0, 0, 0);
			    $deltafreqs1[$tagid1] = 1;
			    $cost += &addmorph($mrp1, $mrpid1, $rperp1, 
					      $lperp1, @deltafreqs1);
			    $cost += $diffcostclasses1[$tagid1];
			    # Add cost of letters if submorph1 is new
			    $cost += &addletters($morph1, 1)
				if ($freqs[$mrpid1][0] == 1);
			    # Pointer and emission cost of submorph2
			    my(@deltafreqs2) = (1, 0, 0, 0, 0);
			    $deltafreqs2[$tagid2] = 1;
			    $cost += &addmorph($mrp2, $mrpid2, $rperp2,
					       $lperp2, @deltafreqs2);
			    $cost += $diffcostclasses2[$tagid2];
			    # Add cost of letters if submorph2 is new
			    $cost += &addletters($morph2, 1)
				if ($freqs[$mrpid2][0] == 1);
			    # Transition probs within sub-structure
			    $cost += $logptag{$tagset[$tagid1]};
			    $cost += $logptrans[$tagid1][$tagid2];
			    # Emission probs of parent morph
			    $submorphs{$mrp} = "$mrp1 $tagid1 $mrp2 $tagid2";
			    $ppres{$mrp1} = $ppre1;
			    $pstms{$mrp1} = $pstm1;
			    $psufs{$mrp1} = $psuf1;
			    $pnomos{$mrp1} = $pnomo1;
			    $ppres{$mrp2} = $ppre2;
			    $pstms{$mrp2} = $pstm2;
			    $psufs{$mrp2} = $psuf2;
			    $pnomos{$mrp2} = $pnomo2;
			    @diffclassprobs = 
				&computecostofclasses($mrp, $rperp, $lperp,
						      \@freqs0);
			    foreach $tagid (1 .. $maxtag) {
				$cost += $diffclassprobs[$tagid];
			    }
			    # Token / type distribution cost
			    $cost += &frequencycost();
			    if ($cost < $bestcost) {
				$bestcost = $cost;
				@bestsolution = 
				    ($mrp, $mrp1, $tagid1, $mrp2, $tagid2);
			    }
			    # Cancel the changes made during this test
#			    print "## (3) Removing 2. morph \"$mrp2\" with ID \"$mrpid2\"\n";
			    &removemorph($mrp2, $mrpid2, @deltafreqs2);
#			    print "## (3) Removing 1. morph \"$mrp1\" with ID \"$mrpid1\"\n";
			    &removemorph($mrp1, $mrpid1, @deltafreqs1);
			}
		    }
		}
	    }
	}
	# Cancel the changes made during this test
#	print "## (3) Removing 0: morph \"$mrp\" with ID \"$mrpid\"\n";
	delete $submorphs{$mrp} if (defined $submorphs{$mrp});
	&removemorph($mrp, $mrpid, @freqs0);
    }
			    
    # (4) Choose the best alternative
    #

    my($mrp1, $mrp2, $tagid1, $tagid2);
    ($mrp, $mrp1, $tagid1, $mrp2, $tagid2) = @bestsolution;

    # Code main morph
    $mrpid = $idsofmorphs{$mrp};
    unless ($mrpid) {	# New morph
	$lastmorphid++;
	$mrpid = $lastmorphid;
	$idsofmorphs{$mrp} = $mrpid;
	@{$freqs[$mrpid]} = (0, 0, 0, 0, 0);
    }
    &addmorph($mrp, $mrpid, $rperp, $lperp, @freqs0);

    if ($mrp1) {	# Submorph structure
	# Submorph1
	my($mrpid1) = $idsofmorphs{$mrp1};
	unless ($mrpid1) {	# New morph
	    $lastmorphid++;
	    $mrpid1 = $lastmorphid;
	    $idsofmorphs{$mrp1} = $mrpid1;
	    @{$freqs[$mrpid1]} = (0, 0, 0, 0, 0);
	}
	my($rperp1) = $rperps{$mrp1};
	my($lperp1);
	if (defined $rperp1) {
	    $lperp1 = $lperps{$mrp1};
	}
	else {
	    # Undefined perplexities: Assume that this submorph
	    # only exists as a submorph of the current morph, which
	    # yields:
	    $rperp1 = 1;
	    $lperp1 = 1; # $lperp;
	    $rperps{$mrp1} = $rperp1;
	    $lperps{$mrp1} = $lperp1;
	}
	my(@deltafreqs1) = (1, 0, 0, 0, 0);
	$deltafreqs1[$tagid1] = 1;
	&addmorph($mrp1, $mrpid1, $rperp1, $lperp1, @deltafreqs1);
	my($ppre1, $pstm1, $psuf1, $pnomo1) = 
	    &getclassprobs($mrp1, $rperp1, $lperp1);
	$ppres{$mrp1} = $ppre1;
	$pstms{$mrp1} = $pstm1;
	$psufs{$mrp1} = $psuf1;
	$pnomos{$mrp1} = $pnomo1;

	# Submorph2
	my($mrpid2) = $idsofmorphs{$mrp2};
	unless ($mrpid2) {	# New morph
	    $lastmorphid++;
	    $mrpid2 = $lastmorphid;
	    $idsofmorphs{$mrp2} = $mrpid2;
	    @{$freqs[$mrpid2]} = (0, 0, 0, 0, 0);
	}
	my($rperp2) = $rperps{$mrp2};
	my($lperp2);
	if (defined $rperp2) {
	    $lperp2 = $lperps{$mrp2};
	}
	else {
	    # Undefined perplexities: Assume that this submorph
	    # only exists as a submorph of the current morph, which
	    # yields:
	    $rperp2 = 1; # $rperp;
	    $lperp2 = 1;
	    $rperps{$mrp2} = $rperp2;
	    $lperps{$mrp2} = $lperp2;
	}
	my(@deltafreqs2) = (1, 0, 0, 0, 0);
	$deltafreqs2[$tagid2] = 1;
	&addmorph($mrp2, $mrpid2, $rperp2, $lperp2, @deltafreqs2);
	my($ppre2, $pstm2, $psuf2, $pnomo2) = 
	    &getclassprobs($mrp2, $rperp2, $lperp2);
	$ppres{$mrp2} = $ppre2;
	$pstms{$mrp2} = $pstm2;
	$psufs{$mrp2} = $psuf2;
	$pnomos{$mrp2} = $pnomo2;

	$submorphs{$mrp} = "$mrp1 $tagid1 $mrp2 $tagid2";
    }

    my($ppre, $pstm, $psuf, $pnomo) = &getclassprobs($mrp, $rperp, $lperp);
    $ppres{$mrp} = $ppre;
    $pstms{$mrp} = $pstm;
    $psufs{$mrp} = $psuf;
    $pnomos{$mrp} = $pnomo;
    
    if (($mrp ne $morph) ||
	((defined $submorphs{$mrp}) && 
	 (defined $submorphs0) && 
	 ($submorphs{$mrp} ne $submorphs0))) {
	# The representation was changed
	$nchanges++;
	$changes{$morph} = "$mrp $nchanges";

	# Diagnostic output
	print "# $morph";
	if ($submorphs0) {
	    my($m1, $t1, $m2, $t2) = split(m/ /, $submorphs0);
	    print " ($m1/$tagset[$t1]+$m2/$tagset[$t2])";
	}
	print " => $mrp";
	if ($submorphs{$mrp}) {
	    my($m1, $t1, $m2, $t2) = split(m/ /, $submorphs{$mrp});
	    print " ($m1/$tagset[$t1]+$m2/$tagset[$t2])";
	}
	print " [" . $freqs0[0] . "," . $freqs[$mrpid][0] . "]";
	print " NEW" if ($mrp1 || ($freqs0[0] == $freqs[$mrpid][0]));
	# The morph is new if it has substructure (and either the morph
	# or the sub-structure is not the same as before) OR it does not
	# have sub-structure and all the frequency of the new morph
	# comes from this instance.
	print "\n";
    }
}


# Remove the current representation of the morph. 
# This function proceeds recursively and removes substructures of morphs
# when appropriate. No value is returned, since it is insignificant to know
# what cost is saved by removing the current representation.

sub removemorph {
    my($morph) = shift @_;	# The morph.
    my($morphid) = shift @_;	# The ID of the morph.
    my(@deltafreqs) = ();	# The occurences specified for each class
    push @deltafreqs, @_;	# separately.

    # Update frequency counters
    print "### No morphid defined for morph \"$morph\"\n" unless ($morphid);
    my($newfreq) = $freqs[$morphid][0] - $deltafreqs[0];
    $nmorphtokens -= $deltafreqs[0];
    my($tagid);
    foreach $tagid (0 .. $maxtag) {
	unless (defined $freqs[$morphid][$tagid]) {
	    print "### No freqs for tagid \"$tagid\" for morph \"$morph\"\n";
	}
	unless (defined $deltafreqs[$tagid]) {
	    print "### No deltafreq for tagid \"$tagid\" for morph \"$morph\"\n";
	}
	$freqs[$morphid][$tagid] -= $deltafreqs[$tagid];
    }
    if ($newfreq == 0) {
	# The morph was removed completely, since its frequency is now zero
	$nmorphtypes--;
	if (defined $ppres{$morph}) {
	    delete $ppres{$morph};  # Delete the current P(Tag | morph) 
	    delete $pstms{$morph};  # probabilities
	    delete $psufs{$morph};
	    delete $pnomos{$morph};
	}

	if ($submorphs{$morph}) {
	    # The morph consists of submorphs: Remove one occurrence
	    # of each submorph ...
	    unless ($leavesubstruct) {
		my($morph1, $subtagid1, $morph2, $subtagid2) =
		    split(m/ /, $submorphs{$morph});
		$morph1 = &changed($morph1); # Follow chain of changes
		$morph2 = &changed($morph2); #  -"-
		my(@deltalist) = (1, 0, 0, 0, 0);
		$deltalist[$subtagid1] = 1;
		&removemorph($morph1, $idsofmorphs{$morph1}, @deltalist);
		@deltalist = (1, 0, 0, 0, 0);
		$deltalist[$subtagid2] = 1;
		&removemorph($morph2, $idsofmorphs{$morph2}, @deltalist);
	    }
	    delete $submorphs{$morph};	# The morph no longer exists
	}
    }
}

# Compute the cost of adding occurrences of a morph. The occurrences are
# distributed over the different tags, but the P(Tag | morph) probs are
# not included in this function.

sub addmorph {
    my($morph) = shift @_;	# The morph.
    my($morphid) = shift @_;	# The ID of the morph.
    my($rperp) = shift @_;	# The right perplexity of the morph.
    my($lperp) = shift @_;	# The left perplexity of the morph.
    my(@deltafreqs) = ();	# The occurences specified for each class
    push @deltafreqs, @_;	# separately.

    # Add to counters
    my($oldfreq) = $freqs[$morphid][0];
    my($tagid);
    foreach $tagid (0 .. $maxtag) {
	$freqs[$morphid][$tagid] += $deltafreqs[$tagid];
    }
    # Subtract old cost of morph pointers
    my($diffcost) = -$nmorphtokens*log($nmorphtokens);
    $diffcost += $oldfreq*log($oldfreq) if ($oldfreq > 0);

    # Add new cost of morph pointers
    my($newfreq) = $oldfreq + $deltafreqs[0];

    die "Assertion failed: New freq <= 0 for morph \"$morph\" (old freq: $oldfreq, delta: $deltafreqs[0])\n" if ($newfreq <= 0);
    $nmorphtokens += $deltafreqs[0];
    $diffcost += $nmorphtokens*log($nmorphtokens) - $newfreq*log($newfreq);
    
    if ($oldfreq == 0) {
	# The morph is new, since its previous frequency was zero
	$nmorphtypes++;
	$diffcost += &universalprior($lperp);	# Add coding of
	$diffcost += &universalprior($rperp);	# the perplexities
    }
    return $diffcost;
}

# Compute the influence on the total cost of adding (or removing)
# @delta occurrences of a morph tagged with each class. Note that only
# the effect of the probabilities P(Tag | morph) are computed by this
# function. 

sub computecostofclasses {
    my($morph, $rperp, $lperp, $deltasptr) = @_;

    my($ppre, $pstm, $psuf, $pnomo) =
	&getclassprobs($morph, $rperp, $lperp);

    my($logppre, $logpsuf, $logpstm, $logpnomo);
    if ($ppre == 0) {
	$logppre = -$logprobzero;
    }
    else {
	$logppre = log($ppre);
    }
    if ($psuf == 0) {
	$logpsuf = -$logprobzero;
    }
    else {
	$logpsuf = log($psuf);
    }
    if ($pstm == 0) {
	$logpstm = -$logprobzero;
    }
    else {
	$logpstm = log($pstm);
    }
    $logpnomo = log($pnomo);

    # Difference in total cost due to the new number of morphs
    # when assuming that the morph is tagged with each tag
    my($diffpre) = -$deltasptr->[1]*($logppre + $logptag{"PRE"});
    my($diffstm) = -$deltasptr->[2]*($logpstm + $logptag{"STM"});
    my($diffsuf) = -$deltasptr->[3]*($logpsuf + $logptag{"SUF"});
    my($diffnomo) = -$deltasptr->[4]*($logpnomo + $logptag{"ZZZ"});

    return (0, $diffpre, $diffstm, $diffsuf, $diffnomo);
}


# Returns the probabilities of the morph being a prefix, stem, suffix or
# non-morpheme

sub getclassprobs {
    my($morph, $rperp, $lperp) = @_;

    my($ppre, $psuf, $pstm, $pnomo);
    $ppre = $ppres{$morph};
    if (defined $ppre) { # Existing morph
	$psuf = $psufs{$morph};
	$pstm = $pstms{$morph};
	$pnomo = $pnomos{$morph};
    }
    else {	# New morph
	die "$me: Assertion failed: Need perplexities for morph \"$morph\".\n"
	    unless ($rperp);

	my($len) = length(&deasterisk($morph));

	# Compute emission probs
	my($prelike) = 1/(1 + exp(-$pplslope*($rperp - $pplthresh)));
	my($suflike) = 1/(1 + exp(-$pplslope*($lperp - $pplthresh)));
	my($stmlike) = 1/(1 + exp(-$lenslope*($len - $lenthresh)));

	$pnomo = (1 - $prelike)*(1 - $suflike)*(1 - $stmlike);
	if ($pnomo == 1) {
	    $ppre = 0; 
	    $psuf = 0;
	    $pstm = 0;
	    $pnomo = 1;
	}
	else {
	    $pnomo = 0.001 if ($pnomo < 0.001);
	    my($normcoeff) =
		(1 - $pnomo)/(($prelike**2) + ($suflike**2) + ($stmlike**2));
	    $ppre = ($prelike**2)*$normcoeff;
	    $psuf = ($suflike**2)*$normcoeff;
	    $pstm = 1 - $ppre - $psuf - $pnomo;

	    $ppre = 0 if ($ppre < 0.0000000001);
	    $pstm = 0 if ($pstm < 0.0000000001);
	    $psuf = 0 if ($psuf < 0.0000000001);
	}
	 
	my($submorphstr) = $submorphs{$morph};
	if ($submorphstr) {
	    # This morph has substructure. This may put constraints on
	    # the tag of the morph.
	    my($morph1, $tagid1, $morph2, $tagid2) =
		split(m/ /, $submorphstr);
	    if (($tagid1 == 1) && ($tagid2 == 1)) {
		# The morph consists of two prefixes and can thus be
		# treated as a prefix. Use prefix probability of either
		# submorph, so that the submorph with lower prefix
		# probability is chosen.
		$morph1 = &changed($morph1); # Follow changes
		$ppre = $ppres{$morph1};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph1\" (submorph of \"$morph\").\n"
		    unless (defined $ppre);
		$morph2 = &changed($morph2); # Follow changes
		my($tmp) = $ppres{$morph2};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph2\" (submorph of \"$morph\").\n"
		    unless (defined $tmp);
		$ppre = $tmp if ($tmp < $ppre);
		$psuf = 0;	# Cannot be suffix
		$pstm = 0;	# or stem
		$pnomo = 1 - $ppre if ($pnomo > 1 - $ppre);	# Total prob
								# max = 1
		}
	    elsif (($tagid1 == 3) && ($tagid2 == 3)) {
		# The morph consists of two suffixes and can thus be
		# treated as a suffix. Use suffix probability of either
		# submorph, so that the submorph with lower suffix
		# probability is chosen.
		$morph1 = &changed($morph1); # Follow changes
		$psuf = $psufs{$morph1};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph1\" (submorph of \"$morph\").\n" 
		    unless (defined $psuf);
		$morph2 = &changed($morph2); # Follow changes
		my($tmp) = $psufs{$morph2};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph2\" (submorph of \"$morph\").\n"
		    unless (defined $tmp);
		$psuf = $tmp if ($tmp < $psuf);
		$ppre = 0;	# Cannot be prefix
		$pstm = 0;	# or stem.
		$pnomo = 1 - $psuf if ($pnomo > 1 - $psuf);	# Total prob
								# max = 1
	    }
	    elsif (($tagid1 != 4) && ($tagid2 != 4)) {
		# Don't allow prefixes and suffixes unless either submorph
		# is a non-morpheme. If either submorph is a non-morpheme
		# the morph will work as an entity of its own, and no probs
		# need to be adjusted.
		$ppre = 0;
		$psuf = 0;
	    }
	}
    }
    return ($ppre, $pstm, $psuf, $pnomo);
}

# Add or remove letters from the morph lexicon

sub addletters {
    my($morph, $sign) = @_;	# $sign equals +1 or -1

    my($diffcost) = 0;
    my($letter, $logp);

    foreach $letter (split(m//, $morph)) {
	$logp = $letterlogprob{$letter};
	$logp = $logpunknownletter unless (defined $logp);
	$diffcost += $logp;
    }
    $diffcost += $letterlogprob{" "};	# End-of-morph character

    return $sign*$diffcost;
}

# Compute the number of nats that are necessary for coding a positive integer
# according to Rissanen's universal prior

sub universalprior {
    my($posnumber) = shift @_;

    return $logc + log($posnumber);
}

# Compute part of the total coding cost of the model

sub frequencycost {

    # Enumerative morph frequency distribution (cf. Rissanen)
    #
    my($freqcost);
    $freqcost = $nmorphtokens*log($nmorphtokens)
	- ($nmorphtypes - 1)*log($nmorphtypes - 1)
	- ($nmorphtokens - $nmorphtypes + 1)*
	log($nmorphtokens - $nmorphtypes + 1);

    # Free order of morphs in lexicon: multiply by (nmorphtypes)!
    #
    $freqcost -= $nmorphtypes*(log($nmorphtypes) - 1);

    # Add header to every morph. We use fixed probabilities: prob. = 1/2 of
    # being a morph *with* substructure and prob. = 1/2 of being a morph
    # *without* substructure:
    $freqcost += $nmorphtypes*$log2;

    return $freqcost;
}

# Test whether there is a chain of changes for the morph, and if there
# is, remove it if the last morph in the chain has been removed completely

sub changeobstacles {
    my($morph) = shift @_;

    return 0 unless (defined $changes{$morph});	# No obstacle

    my($newmorph) = &changed($morph);

    return 1 if ($freqs[$idsofmorphs{$newmorph}][0]);	# There is an
							# obstacle: The
							# chain is valid.
    # The chain points to a morph without any occurrences. Remove
    # the invalid chain:
    my($i);
    while (defined $changes{$morph}) {
	($newmorph, $i) = split(m/ /, $changes{$morph});
	print "## Removing change $morph -> $newmorph\n";
	delete $changes{$morph};
	$morph = $newmorph;
    }
    return 0;	# No obstacle
}

# Follow the chain of changes, but avoid circles, if one morph has changed
# back to itself through some steps

sub changed {
    my($morph) = shift @_;

    return $morph unless (defined $changes{$morph});

#    print "#### $morph";
    my($oldi);
    ($morph, $oldi) = split(m/ /, $changes{$morph});

#    print " => $morph";
    my($newmorph, $i);
    while (defined $changes{$morph}) {
	($newmorph, $i) = split(m/ /, $changes{$morph});
	return $morph if ($i <= $oldi);	# Avoid circles
	$morph = $newmorph;
	$oldi = $i;
#	print " => $morph";
    }

#    print "\n";
    return $morph;
}

sub deasterisk {
    my($morph) = shift @_;
    $morph =~ s/\*[0-4]$//;	# Remove asterisk and number at the end
    return $morph;
}

sub usage {
    die "Usage: $me [-pplthresh float] [-pplslope float] [-lenthresh float] " .
	"[-lenslope float] [-maxchanges int] -probs probsfile " .
	"-alphabet alphabetfile -segmentation morph_segmentation\n";
}
