#!/usr/bin/perl -w
#
# joinmorphs.pl [-pplthresh float] [-pplslope float]
#               [-lenthresh float] [-lenslope float] [-minppllen int] 
#               [-wtypeppl | -wtokenppl] [-maxchanges int] -probs probsfile
#               -alphabet alphabetfile -segmentation morph_segmentation
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
$usewordtypeppl = 1;  # Whether to use word counts when computing predecessor
		      # and successor perplexities 
$maxchanges = 10000;  # The maximal number of bigrams that are joined
		      # during this iteration
$probsfile = "";      # Probability file (output of estimateprobs.pl)
$alphabetfile = "";   # Probability distribution over alphabet
$segfile = "";	      # Morph segmentation file
$minppllen = 4;	      # Morphs shorter than this value are excluded when the
		      # context of a morph is collected (in order to compute
		      # left and right perplexity).

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
    elsif ($arg eq '-wtypeppl') {
	$usewordtypeppl = 1;
    }
    elsif ($arg eq '-wtokenppl') {
	$usewordtypeppl = 0;
    }
    elsif ($arg eq "-maxchanges") {
	$maxchanges = shift @ARGV;
	&usage() unless ($maxchanges =~ m/^[0-9]+$/);
    }
    elsif ($arg eq '-minppllen') {
	$minppllen = shift @ARGV;
	&usage() unless ($minppllen =~ m/^[0-9]+$/);
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
if ($usewordtypeppl) {
    print "# -wtypeppl: yes\n";
}
else {
    print "# -wtypeppl: no (-wtokenppl)\n";
}
print "# -minppllen $minppllen\n";
print "# -maxchanges $maxchanges\n";
print "# -probs \"$probsfile\"\n";
print "# -alphabet \"$alphabetfile\"\n";
print "# -segmentation \"$segfile\"\n";

$maxtag = -1;
%tagids = ();
@tagset = ();
$nshortmorphs = 0;	# Number of morphs shorter than $minppllen

#$maxmorphid = 0;
#%morphids = ();
#$morphids{' '} = 0;	# Word boundary
#@morphnames[0] = ' ';   # -"-

# Read initial probabilities

$logprobzero = 1000000;

print "# Reading transition and category probabilities from file \"$probsfile\"...\n";

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
    elsif ($line =~ m/^\#P\(Tag\|\"(.+)\"\)\t([\.0-9]+)\t([\.0-9]+)\t([\.0-9]+)\t([\.0-9]+)$/) {
	$morph = $1;
	$ppre = $2;
	$pstm = $3;
	$psuf = $4;
	$pnomo = $5;
	$morph =~ s/\*0$//; # No asterisks for non-recursive morphs
	$ppres{$morph} = $ppre;
	$pstms{$morph} = $pstm;
	$psufs{$morph} = $psuf;
	$pnomos{$morph} = $pnomo;
	$nshortmorphs++ if (length(&deasterisk($morph)) < $minppllen);
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

$nmorphtypes = 0; # Number of unique morph strings
$lastmorph = 0;   # Ordinal number of last morph read so far
		  # (including word breaks)
$morphids[0] = 0; # Numeral ID of the ith morph
$tags[0] = 0;	  # Tag of the ith morph
$counts[0] = 0;	  # Count of the ith morph (equals word count of the word the
		  # morph occurs in)
$lastshortmorphid = 0;	# Points to the last morph ID that was occupied ...
$lastlongmorphid = $nshortmorphs; # by short and long morphs respectively

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
	    $issubstructure = 1;
	    $contexttype = shift @morphs;
	    ($morph1, $tag1) = split(m:/:, $morphs[0]);
	    ($morph2, $tag2) = split(m:/:, $morphs[1]);
	    $morph1 =~ s/\*0$//; # No asterisks for non-recursive morphs
	    $morph2 =~ s/\*0$//; # -"-
	    $submorphs{&deasterisk($morph1) . &deasterisk($morph2) .
			   $contexttype} = join(" ",  $morph1, $tagids{$tag1},
						$morph2, $tagids{$tag2});
	}
	else {
	    $issubstructure = 0;
	}

	# Collect info about morph unigrams
	@morphsnotags = ();
	foreach $morphandtag (@morphs) {
	    ($morph, $tag) = split(m:/:, $morphandtag);
	    $morph =~ s/\*0$//;		# No asterisks for non-recursive morphs
	    $freqs{$morph} += $wcount;	# Frequency of morph
	    $nmorphtokens += $wcount;	# Total number of morphs
	    next if ($issubstructure);

	    # Store tag and word count in data structure
	    $lastmorph++;
	    $morphid = $idsofmorphs{$morph};
	    unless (defined $morphid) {
		$nmorphtypes++;
		if (length(&deasterisk($morph)) < $minppllen) {
		    $lastshortmorphid++;
		    $morphid = $lastshortmorphid;
		}
		else {
		    $lastlongmorphid++;
		    $morphid = $lastlongmorphid;
		}
		$idsofmorphs{$morph} = $morphid;
	    }
	    $morphids[$lastmorph] = $morphid;
	    $counts[$lastmorph] = $wcount;
	    $tags[$lastmorph] = $tagids{$tag};
	    push @morphsnotags, $morph;
	}
	next if ($issubstructure);
	$lastmorph++;
	# Word boundary morph (used both for words and substructs)
	$morphids[$lastmorph] = 0; # Word boundary "morph"
	$counts[$lastmorph] = $wcount;
	$tags[$lastmorph] = 0;

	# Collect info about morph bigrams
	next if (scalar(@morphsnotags) == 1);	# No bigram here
	foreach $i (0 .. $#morphsnotags - 1) {	# $i = idx within this word
	    $j = $lastmorph - scalar(@morphsnotags) + $i;
						# $j = idx in data struct
                                                # of first morph in bigram
	    $ctxttagid1 = $tags[$j - 1];        # Tags of morphs preceding
	    $ctxttagid2 = $tags[$j + 2];	# and succeeding the bigram
	    $tagid1 = $tags[$j];		# Tags of the morphs in
	    $tagid2 = $tags[$j+1];		# the bigram
	    $morph1 = $morphsnotags[$i];	# Morphs in the bigram
	    $morph2 = $morphsnotags[$i+1];	# -"-

	    if ($ctxttagid1 < 2) {	# word boundary or prefix
		if (($ctxttagid2 == 0) || ($ctxttagid2 == 3)) { # word bound.
		    $ctxttype = 3;				# or suffix
		}
		else {
		    $ctxttype = 1;
		}
	    }
	    else {
		if (($ctxttagid2 == 0) || ($ctxttagid2 == 3)) { # word bound.
		    $ctxttype = 2;				# or suffix
		}
		else {
		    $ctxttype = 4;
		}
	    }
	    $bigramstr = join(" ", $morph1, $tagid1,
			      $morph2, $tagid2, $ctxttype);
	    $bigramfreqs{$bigramstr} += $wcount;	# Bigram frequency
	    # Locations of context-specific bigram
	    push @{$cdlocations{$bigramstr}}, $j;

	    # Locations of context-independent bigrams
	    push @{$cilocations{&deasterisk($morph1) . &deasterisk($morph2)}},
	    $j;
	}
    }
}

close SEGS;

die "$me: Assertion failed: Error in constructing data structure and " .
    "separating short and long morphs.\n"
    if (($lastshortmorphid > $nshortmorphs) ||
	($lastlongmorphid > $nshortmorphs + $nmorphtypes - $lastshortmorphid));

print "# Sorting bigrams...\n";

@sortedbigramstrings =
    sort {$bigramfreqs{$b} <=> $bigramfreqs{$a}} keys %bigramfreqs;

print "# Joining bigrams...\n";

$nchanges = 0;
foreach $bigramstr (@sortedbigramstrings) {
    last if ($nchanges == $maxchanges);
    ($morph1, $tagid1, $morph2, $tagid2, $ctxttype) = split(/ /, $bigramstr);
    $tag1 = $tagset[$tagid1];
    $tag2 = $tagset[$tagid2];
#    print "# $morph1/$tag1+$morph2/$tag2(*$ctxttype)\t$bigramfreqs{$bigramstr}\n";
    &trytojoinbigram($bigramstr);
}

# Collect a list of the morphs that need to get a *0 appended to their names,
# i.e., morphs that have no substructure in a particular context, but do
# have substructure in another context.
foreach $morph (keys %submorphs) {
    $morphstr = &deasterisk($morph);
    if ($freqs{$morphstr}) {
	$zeromorphs{$morphstr} = 1;
    }
}

# Rename the morh IDs in the segmentation data structure by
# negative integers identifying all accepted join operations
$i = 0;
@changelist = ();
foreach $bigramstr (@sortedbigramstrings) {
    if ($changes{$bigramstr}) {
	$i++;
	$changelist[$i] = $changes{$bigramstr};
	foreach $j (@{$cdlocations{$bigramstr}}) {
	    # Mark the location for a change
	    # (unless it has already been marked)
	    if (($morphids[$j] > 0) && ($morphids[$j+1] > 0)) {
		$morphids[$j] = -$i;
		$morphids[$j+1] = -$i;
	    }
	}
    }
}

# Read the segmentation file and output the joined representations

$lastmorph = 0;

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

	$i = 0;
	while ($i <= $#morphs) {
	    ($morph, $tag) = split(m:/:, $morphs[$i]);
	    $lastmorph++;
	    $changeid = -$morphids[$lastmorph];
	    if ($changeid > 0) {
		# Do a replacement
		($morph, $tagid) = split(m/ /, $changelist[$changeid]);
		$tag = $tagset[$tagid];
		$i++;	# It was a join: Skip the next one
		$lastmorph++;
	    }
	    $morph .= "*0" if (defined $zeromorphs{$morph});
	    push @morphsout, "$morph/$tag";
	    $i++;
	}
	print join(" + ", @morphsout) . "\n";
	$lastmorph++;	# Word boundary
    }
}

close SEGS;

foreach $morph (keys %submorphs) {
    ($tail = $morph) =~ s/^[^\*]+//;
    ($submorph1, $tagid1, $submorph2, $tagid2) =
	split(m/ /, $submorphs{$morph});
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

sub trytojoinbigram {
    my($bigramstr) = shift @_;

    my($morph1, $tagid1, $morph2, $tagid2, $ctxttype) =
	split(m/ /, $bigramstr);

    my($morph0) = &deasterisk($morph1) . &deasterisk($morph2); # joined morph
    my(@predecessortags, @successortags);
    # Frequency of joined morph within current context type:
    my($freq0) = &getbigramfreqandcontext($bigramstr, \@predecessortags,
					  \@successortags);
    return if ($freq0 == 0);
    # Compute right and left perplexity of the new morph
    my($rperp, $lperp) = &computebigramperplexities($morph0);

    # Remove current (bigram) representation:
    # All alternative solutions contain the removal of the current
    # representation. Put the baseline cost at this level. A better solution
    # must come up with an added cost that is *less* than the cost of the
    # removed morphs. Otherwise the new representation is no good.
    my($bestcost) = &frequencycost();
    $bestcost -= &removebigram($bigramstr, $freq0, $rperp, $lperp,
			       \@predecessortags, \@successortags);
    # @bestsolution contains the name of the joined morph, its tag ID, and
    # the tag IDs of its submorphs.
    # The following value identifies the no-change solution:
    my(@bestsolution) = ("", 0, $tagid1, $tagid2);

    my($mrp);
    # Test whether this morph string already exists as a morph in *some*
    # context and whether that representation works well in the current
    # context as well.
    my(@alternatives) = ();
    push @alternatives, $morph0 if ($freqs{$morph0});
    push @alternatives, $morph0 . "*1" if ($freqs{$morph0 . "*1"});
    push @alternatives, $morph0 . "*2" if ($freqs{$morph0 . "*2"});
    push @alternatives, $morph0 . "*3" if ($freqs{$morph0 . "*3"});
    push @alternatives, $morph0 . "*4" if ($freqs{$morph0 . "*4"});
    if (scalar(@alternatives) > 0) {
	# This morph *does* exist in some context

	# Morph token / type frequency distribution:
	$nmorphtokens += $freq0;
	my($freqcost) = &frequencycost();
	$nmorphtokens -= $freq0;

	# Test the alternatives
	foreach $mrp (@alternatives) {
	    my(@costs) =
		&addjoinedmorph($mrp, $freq0, $rperp, $lperp, $submorphs{$mrp},
				\@predecessortags, \@successortags);
	    my($tagid);
	    foreach $tagid (1 .. 4) {
		if ($costs[$tagid-1] + $freqcost < $bestcost) {
		    $bestcost = $costs[$tagid-1] + $freqcost;
		    @bestsolution = ($mrp, $tagid, 0, 0);
		}
	    }
	}
    }

    unless ($freqs{$morph0}) {
	# This morph does not exist in the lexicon. Try to add it and
	# compute cost.
	my(@costs) = &addjoinedmorph($morph0, $freq0, $rperp, $lperp, "",
				     \@predecessortags, \@successortags);
	# Code letters
	my($lexiconcost) = &addletters($morph0, 1);
	# Code perplexities
	$lexiconcost += &universalprior($lperp) + &universalprior($rperp);
	$nmorphtokens += $freq0;
	$nmorphtypes++;
	$lexiconcost += &frequencycost();
	my($tagid);
	foreach $tagid (1 .. 4) {
	    if ($costs[$tagid-1] + $lexiconcost < $bestcost) {
		$bestcost = $costs[$tagid-1] + $lexiconcost;
		@bestsolution = ($morph0, $tagid, 0, 0);
	    }
	}
	$nmorphtokens -= $freq0;
	$nmorphtypes--;
    }

    $mrp = $morph0 . "*" . $ctxttype;
    unless ($freqs{$mrp}) {
	# This morph does not have substructure in the current context.
	# Test all possible taggings and compute cost.

	# First compute the costs of the submorphs
	# Submorph 1
	my(@costssubmorph1) = &addmorph($morph1, 1, 0, 0, $submorphs{$morph1});
	$freqs{$morph1}++;
	$nmorphtokens++;
	my($lexiconcost) = 0;
	if ($freqs{$morph1} == 1) {
	    # New morph
	    $nmorphtypes++;
	    # Assume that the left perplexity of morph1 equals the left
	    # perplexity of the bigram, and that the right perplexity of
	    # morph1 equals one:
	    $lexiconcost += &universalprior($lperp);
	    $lexiconcost += &universalprior(1);
	    if (!($submorphs{$morph1})) {
		# The morph does not have substructure.
		# Add letters to the lexicon.
		$lexiconcost += &addletters(&deasterisk($morph1), 1);
	    }
	}
	
	# Submorph 2
	my(@costssubmorph2) = &addmorph($morph2, 1, 0, 0, $submorphs{$morph2});
	$freqs{$morph2}++;
	$nmorphtokens++;
	if ($freqs{$morph2} == 1) {
	    # New morph
	    $nmorphtypes++;
	    # Assume that the right perplexity of morph2 equals the right
	    # perplexity of the bigram, and that the left perplexity of
	    # morph2 equals one:
	    $lexiconcost += &universalprior(1);
	    $lexiconcost += &universalprior($rperp);
	    if (!($submorphs{$morph2})) {
		# The morph does not have substructure.
		# Add letters to the lexicon.
		$lexiconcost += &addletters(&deasterisk($morph2), 1);
	    }
	}

	# Morph token / type distribution:
	$nmorphtokens += $freq0;
	$nmorphtypes++;
	$lexiconcost += &frequencycost();
	$nmorphtokens -= $freq0;
	$nmorphtypes--;

	my($subtagid1, $subtagid2);
	foreach $subtagid1 (1 .. 4) {
	    foreach $subtagid2 (1 .. 4) {
		# Subtags may not be SUF + PRE or SUF + STM
		next if (($subtagid1 == 3) &&
			 (($subtagid2 == 1) || ($subtagid2 == 2)));
		# Subtags may not be STM + PRE
		next if (($subtagid1 == 2) && ($subtagid2 == 1));
		my(@costs) =
		    &addjoinedmorph($mrp, $freq0, $rperp, $lperp,
				    "$morph1 $subtagid1 $morph2 $subtagid2",
				    \@predecessortags, \@successortags);
		my($tagid);
		foreach $tagid (1 .. 4) {
		    my($cost) = $costs[$tagid-1] + 
			$logptag{$tagset[$subtagid1]} +
			$costssubmorph1[$subtagid1-1] + 
			$logptrans[$subtagid1][$subtagid2] +
			$costssubmorph2[$subtagid2-1] +
			$lexiconcost;
		    if ($cost < $bestcost) {
			$bestcost = $cost;
			@bestsolution = ($mrp, $tagid, $subtagid1, $subtagid2);
		    }
		}
	    }
	}

	$freqs{$morph1}--;
	$freqs{$morph2}--;
	$nmorphtokens -= 2;
	$nmorphtypes-- if ($freqs{$morph1} == 0);
	$nmorphtypes-- if ($freqs{$morph2} == 0);
    }

    # Choose the best alternative
    my($tagid, $subtagid1, $subtagid2);
    ($mrp, $tagid, $subtagid1, $subtagid2) = @bestsolution;
    if ($mrp eq "") {	# No change
	# Restore morph frequencies
	$nmorphtypes++ if ($freqs{$morph1} == 0);
	$nmorphtypes++ if ($freqs{$morph2} == 0);
	$freqs{$morph1} += $freq0;
	$freqs{$morph2} += $freq0;
	$nmorphtokens += 2*$freq0;
    }
    else {	# Accept join
	$nmorphtokens += $freq0;	# Add frequencies
	if (defined $freqs{$mrp}) {	# Existing morph
	    $freqs{$mrp} += $freq0;
	}
	else {				# New morph
	    $freqs{$mrp} = $freq0;
	    $nmorphtypes++;
	    if ($mrp ne $morph0) {	# There is substructure
		$nmorphtypes++ if ($freqs{$morph1} == 0);
		$nmorphtypes++ if ($freqs{$morph2} == 0);
		$freqs{$morph1}++;
		$freqs{$morph2}++;
		$nmorphtokens += 2;
		$submorphs{$mrp} = "$morph1 $subtagid1 $morph2 $subtagid2";
	    }
	}
	# Update data structure representing segmentation
	my($locs) = $cdlocations{$bigramstr};
	my($i);
	foreach $i (@$locs) {
	    $tags[$i] = $tagid;			# Update tags
	    $tags[$i+1] = $tagid;
	    $counts[$i] = -$counts[$i];		# Mark this bigram as
	    $counts[$i+1] = -$counts[$i+1];	# processed
	}
	$changes{$bigramstr} = "$mrp $tagid";
	$nchanges++;

	# Diagnostic output
	my($tag0) = $tagset[$tagid];
	my($tag1) = $tagset[$tagid1];
	my($tag2) = $tagset[$tagid2];
	my($extra) = "";
	if ($submorphs{$mrp}) {
	    my($m1, $t1, $m2, $t2) = split(m/ /, $submorphs{$mrp});
	    $extra = "($m1/$tagset[$t1]+$m2/$tagset[$t2]) ";
	}
	
	print "# $morph1/$tag1+$morph2/$tag2(*$ctxttype) => $mrp/$tag0 $extra" 
	    . "[" . $freq0 . "," . $freqs{$mrp} . "]\n";
    }
}


# Compute the gain in cost that is obtained by removing the occurrences
# of the the two morphs in the bigram

sub removebigram {
    my($bigramstr, $freq, $rperp, $lperp,
       $predecessortagsptr, $successortagsptr) = @_;

    my($morph1, $tagid1, $morph2, $tagid2, $ctxttype) =
	split(m/ /, $bigramstr);
    my($diffcost) = 0;

    # Remove transition probs to and from and within the bigram
    my($ctxttagid);
    foreach $ctxttagid (0 .. 4) {
	$diffcost -=
	    $predecessortagsptr->[$ctxttagid]*$logptrans[$ctxttagid][$tagid1]
	    + $successortagsptr->[$ctxttagid]*$logptrans[$tagid2][$ctxttagid];
    }
    $diffcost -= $freq*$logptrans[$tagid1][$tagid2];

    # Remove morph emission probs and letters from lexicon if
    # no occurrences of the morph is left

    # Morph1
    $diffcost +=
	(&addmorph($morph1, -$freq, 0, 0, $submorphs{$morph1}))[$tagid1-1];
    $freqs{$morph1} -= $freq;
    $nmorphtokens -= $freq;
    if ($freqs{$morph1} == 0) {
	# There are no occurrences left of this morph type.
	$nmorphtypes--;
	# Assume that the left perplexity of morph1 equals the left perplexity
	# of the bigram, and that the right perplexity of morph1 equals one:
	# (This because we haven't stored the real perplexities.)
	$diffcost -= &universalprior($lperp);
	$diffcost -= &universalprior(1);
	if (!($submorphs{$morph1})) {
	    # There are no occurrences left and the morph doesn't
	    # have substructure: Remove letters from lexicon
	    $diffcost += &addletters(&deasterisk($morph1), -1);
	}
    }

    # Morph2
    $diffcost +=
	(&addmorph($morph2, -$freq, 0, 0, $submorphs{$morph2}))[$tagid2-1]; 
    $freqs{$morph2} -= $freq;
    $nmorphtokens -= $freq;
    if ($freqs{$morph2} == 0) {
	# There are no occurrences left of this morph type.
	$nmorphtypes--;
	# Assume that the right perplexity of morph2 equals the right perpl.
	# of the bigram, and that the left perplexity of morph2 equals one:
	# (This because we haven't stored the real perplexities.)
	$diffcost -= &universalprior(1);
	$diffcost -= &universalprior($rperp);
	if (!($submorphs{$morph2})) {
	    # There are no occurrences left and the morph doesn't
	    # have substructure: Remove letters from lexicon
	    $diffcost += &addletters(&deasterisk($morph2), -1);
	}
    }    

    return $diffcost;
}


# Compute the cost of adding occurrences of a morph that has been produced
# by joining two morphs in a bigram. Four values are returned, one for
# every tagging of the joined morph.

sub addjoinedmorph {
    my($morph, $freq, $rperp, $lperp, $submorphstr,
       $predecessortagsptr, $successortagsptr) = @_;

    # Emission probs cost additions for every possible tagging:
    my(@costs) =
	&addmorph($morph, $freq, $rperp, $lperp, $submorphstr);
    
    # Add contribution of transition probs
    my($tagid, $ctxttagid);
    foreach $tagid (1 .. 4) {
	foreach $ctxttagid (0 .. 4) {
	    $costs[$tagid-1] +=
		$predecessortagsptr->[$ctxttagid]*
		$logptrans[$ctxttagid][$tagid]
		+ $successortagsptr->[$ctxttagid]*
		$logptrans[$tagid][$ctxttagid];
	}
    }

    return @costs;
}

# Get the updated frequency of a morph bigram, when some bigrams have
# already been joined and thus the old frequency may not be correct anymore.
# Also get the number of occurrences of every tag preceding and succeeding the
# bigram.

sub getbigramfreqandcontext {
    my($bigramstr, $predecessortagsptr, $successortagsptr) = @_;

    my($locs) = $cdlocations{$bigramstr};
    die "Assertion failed ($me): Undefined bigram string \"$bigramstr\".\n"
	unless (defined $locs);
    
    my($freq) = 0;	# Frequency of bigram
    @$predecessortagsptr = (0, 0, 0, 0, 0); # Frequency of context tags
    @$successortagsptr = (0, 0, 0, 0, 0);   # (word bound, PRE, STM, SUF, ZZZ)
    my($i, $count);
    my($lasti) = -1;
    foreach $i (@$locs) {
	next if ($i == $lasti + 1);	# Don't count the same bigram many
					# times, e.g., xx + xx + xx + xx
	if (($counts[$i] > 0) && ($counts[$i+1] > 0)) {
	    # This bigram occurrence has not changed: count it in
	    $count = $counts[$i];
	    $freq += $count;
	    $predecessortagsptr->[$tags[$i-1]] += $count;
	    $successortagsptr->[$tags[$i+2]] += $count;
	}
	$lasti = $i;
    }

    return $freq;
}

# Compute difference in emission probs resulting from the addition or
# removal of some morph occurrences

sub addmorph {
    # Arguments:
    # $morph: context-dependent morph, e.g., talo*1
    # $deltafreq: how many occurrences of this morph are added or removed
    # $rperp: right perplexity of the morph
    # $lperp: left perplexity of the morph. (The perplexities play no role
    # if there is already a prob. distr. for $morph.)
    # $submorphstr indicates the submorphs and their tags if the morph has 
    # recursive structure (otherwise it is the empty string)
    my($morph, $deltafreq, $rperp, $lperp, $submorphstr) = @_;

    my($oldfreq) = $freqs{$morph};  # Frequency of morph before
                                    # addition or removal
    # Tag-independent part of difference in total cost
    # due to addition or removal of morph:
    my($diffcost) = -$nmorphtokens*log($nmorphtokens);
    if ($oldfreq) {	# Existing morph
	# Tag-independent part of difference in total cost: 
	$diffcost += $oldfreq*log($oldfreq);
    }
    else {	# New morph
	$oldfreq = 0;
    }
    
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
	}
	 
	if ($submorphstr) {
	    # This morph has substructure. This may put constraints on
	    # the tag of the morph.
	    ($morph1, $tagid1, $morph2, $tagid2) =
		split(m/ /, $submorphstr);
	    if (($tagid1 == 1) && ($tagid2 == 1)) {
		# The morph consists of two prefixes and can thus be
		# treated as a prefix. Use prefix probability of either
		# submorph, so that the submorph with lower prefix
		# probability is chosen.
		$ppre = $ppres{$morph1};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph1\".\n" unless (defined $ppre);
		my($tmp) = $ppres{$morph2};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph2\".\n" unless (defined $tmp);
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
		$psuf = $psufs{$morph1};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph1\".\n" unless (defined $psuf);
		my($tmp) = $psufs{$morph2};
		die "$me: Assertion failed: Undefined probs for morph " .
		    "\"$morph2\".\n" unless (defined $tmp);
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
    my($diffpre) = -$deltafreq*($logppre + $logptag{"PRE"});
    my($diffstm) = -$deltafreq*($logpstm + $logptag{"STM"});
    my($diffsuf) = -$deltafreq*($logpsuf + $logptag{"SUF"});
    my($diffnomo) = -$deltafreq*($logpnomo + $logptag{"ZZZ"});

    # Tag-independent part of difference in total cost 
    my($newfreq) = $oldfreq + $deltafreq;
    $diffcost += ($nmorphtokens + $deltafreq)*log($nmorphtokens + $deltafreq);
    $diffcost -= $newfreq*log($newfreq) if ($newfreq > 0);

    # Return difference in cost (new cost - old cost) for each of the
    # four tagging alternatives
    return ($diffcost + $diffpre, $diffcost + $diffstm,
	    $diffcost + $diffsuf, $diffcost + $diffnomo);
}

# Compute left and right perplexities of a particular morph bigram

sub computebigramperplexities {

    my($bigram) = shift @_;

    my($locs) = $cilocations{$bigram};
    die "Assertion failed ($me): Undefined bigram \"$bigram\".\n"
	unless (defined $locs);

    my($i, $count, $leftid, $rightid);
    my(%left, %right);
    my($nlefttok) = 0;
    my($nrighttok) = 0;

    foreach $i (@$locs) {
	if ($usewordtypeppl) {
	    $count = 1;
	}
	else { 
	    $count = $counts[$i];
	    $count = -$count if ($count < 0);	# A negative count means
						# that this morph has been
						# joined with its neighbor
	}

	$leftid = $morphids[$i-1];
	unless (($leftid > 0) && ($leftid <= $nshortmorphs)) {
	    $left{$leftid} += $count;
	    $nlefttok += $count;
	}

	$rightid = $morphids[$i+2];
	unless (($rightid > 0) && ($rightid <= $nshortmorphs)) {
	    $right{$rightid} += $count;
	    $nrighttok += $count;
	}
    }

    my($entropy) = 0;
    my($p, $l, $r, $lperp, $rperp);
    foreach $l (keys %left) {
	$p = $left{$l}/$nlefttok;
	$entropy -= $p*log($p);
    }
    $lperp = exp($entropy);

    $entropy = 0;
    foreach $r (keys %right) {
	$p = $right{$r}/$nrighttok;
	$entropy -= $p*log($p);
    }
    $rperp = exp($entropy);

    return($rperp, $lperp);
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

sub deasterisk {
    my($morph) = shift @_;
    $morph =~ s/\*[0-4]$//;	# Remove asterisk and number at the end
    return $morph;
}

sub usage {
    die "Usage: $me [-pplthresh float] [-pplslope float] [-lenthresh float] " .
	"[-lenslope float] [-wtypeppl | -wtokenppl] [-maxchanges int] " .
	"[-minppllen int] -probs probsfile -alphabet alphabetfile " .
	"-segmentation morph_segmentation\n";
}
