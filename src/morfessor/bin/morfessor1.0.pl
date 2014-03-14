#!/usr/bin/perl -w
# The previous line indicates the location of the Perl interpreter.
# Modify if necessary!
#
#
# morfessor1.0.pl    Words are split into morphs by this program.
#                    Usage at the end of this file.
#
# Copyright (C) 2002-2005 Mathias Creutz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License (below or at http://www.gnu.org/licenses/
# gpl.html) for more details.
#
# The users of the Morfessor program are requested to refer to the
# following technical report in their scientific publications:
#
# Mathias Creutz and Krista Lagus. 2005. Unsupervised Morpheme Segmentation
# and Morphology Induction from Text Corpora Using Morfessor. Publications
# in Computer and Information Science, Report A81, Helsinki University of
# Technology, March. http://www.cis.hut.fi/projects/morpho/
#
#
# -- -- --
#
# 		    GNU GENERAL PUBLIC LICENSE
# 		       Version 2, June 1991
# 
#  Copyright (C) 1989, 1991 Free Software Foundation, Inc.
#                        59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#  Everyone is permitted to copy and distribute verbatim copies
#  of this license document, but changing it is not allowed.
# 
# 			    Preamble
# 
#   The licenses for most software are designed to take away your
# freedom to share and change it.  By contrast, the GNU General Public
# License is intended to guarantee your freedom to share and change free
# software--to make sure the software is free for all its users.  This
# General Public License applies to most of the Free Software
# Foundation's software and to any other program whose authors commit to
# using it.  (Some other Free Software Foundation software is covered by
# the GNU Library General Public License instead.)  You can apply it to
# your programs, too.
# 
#   When we speak of free software, we are referring to freedom, not
# price.  Our General Public Licenses are designed to make sure that you
# have the freedom to distribute copies of free software (and charge for
# this service if you wish), that you receive source code or can get it
# if you want it, that you can change the software or use pieces of it
# in new free programs; and that you know you can do these things.
# 
#   To protect your rights, we need to make restrictions that forbid
# anyone to deny you these rights or to ask you to surrender the rights.
# These restrictions translate to certain responsibilities for you if you
# distribute copies of the software, or if you modify it.
# 
#   For example, if you distribute copies of such a program, whether
# gratis or for a fee, you must give the recipients all the rights that
# you have.  You must make sure that they, too, receive or can get the
# source code.  And you must show them these terms so they know their
# rights.
# 
#   We protect your rights with two steps: (1) copyright the software, and
# (2) offer you this license which gives you legal permission to copy,
# distribute and/or modify the software.
# 
#   Also, for each author's protection and ours, we want to make certain
# that everyone understands that there is no warranty for this free
# software.  If the software is modified by someone else and passed on, we
# want its recipients to know that what they have is not the original, so
# that any problems introduced by others will not reflect on the original
# authors' reputations.
# 
#   Finally, any free program is threatened constantly by software
# patents.  We wish to avoid the danger that redistributors of a free
# program will individually obtain patent licenses, in effect making the
# program proprietary.  To prevent this, we have made it clear that any
# patent must be licensed for everyone's free use or not licensed at all.
# 
#   The precise terms and conditions for copying, distribution and
# modification follow.
# 
# 		    GNU GENERAL PUBLIC LICENSE
#    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 
#   0. This License applies to any program or other work which contains
# a notice placed by the copyright holder saying it may be distributed
# under the terms of this General Public License.  The "Program", below,
# refers to any such program or work, and a "work based on the Program"
# means either the Program or any derivative work under copyright law:
# that is to say, a work containing the Program or a portion of it,
# either verbatim or with modifications and/or translated into another
# language.  (Hereinafter, translation is included without limitation in
# the term "modification".)  Each licensee is addressed as "you".
# 
# Activities other than copying, distribution and modification are not
# covered by this License; they are outside its scope.  The act of
# running the Program is not restricted, and the output from the Program
# is covered only if its contents constitute a work based on the
# Program (independent of having been made by running the Program).
# Whether that is true depends on what the Program does.
# 
#   1. You may copy and distribute verbatim copies of the Program's
# source code as you receive it, in any medium, provided that you
# conspicuously and appropriately publish on each copy an appropriate
# copyright notice and disclaimer of warranty; keep intact all the
# notices that refer to this License and to the absence of any warranty;
# and give any other recipients of the Program a copy of this License
# along with the Program.
# 
# You may charge a fee for the physical act of transferring a copy, and
# you may at your option offer warranty protection in exchange for a fee.
# 
#   2. You may modify your copy or copies of the Program or any portion
# of it, thus forming a work based on the Program, and copy and
# distribute such modifications or work under the terms of Section 1
# above, provided that you also meet all of these conditions:
# 
#     a) You must cause the modified files to carry prominent notices
#     stating that you changed the files and the date of any change.
# 
#     b) You must cause any work that you distribute or publish, that in
#     whole or in part contains or is derived from the Program or any
#     part thereof, to be licensed as a whole at no charge to all third
#     parties under the terms of this License.
# 
#     c) If the modified program normally reads commands interactively
#     when run, you must cause it, when started running for such
#     interactive use in the most ordinary way, to print or display an
#     announcement including an appropriate copyright notice and a
#     notice that there is no warranty (or else, saying that you provide
#     a warranty) and that users may redistribute the program under
#     these conditions, and telling the user how to view a copy of this
#     License.  (Exception: if the Program itself is interactive but
#     does not normally print such an announcement, your work based on
#     the Program is not required to print an announcement.)
# 
# These requirements apply to the modified work as a whole.  If
# identifiable sections of that work are not derived from the Program,
# and can be reasonably considered independent and separate works in
# themselves, then this License, and its terms, do not apply to those
# sections when you distribute them as separate works.  But when you
# distribute the same sections as part of a whole which is a work based
# on the Program, the distribution of the whole must be on the terms of
# this License, whose permissions for other licensees extend to the
# entire whole, and thus to each and every part regardless of who wrote it.
# 
# Thus, it is not the intent of this section to claim rights or contest
# your rights to work written entirely by you; rather, the intent is to
# exercise the right to control the distribution of derivative or
# collective works based on the Program.
# 
# In addition, mere aggregation of another work not based on the Program
# with the Program (or with a work based on the Program) on a volume of
# a storage or distribution medium does not bring the other work under
# the scope of this License.
# 
#   3. You may copy and distribute the Program (or a work based on it,
# under Section 2) in object code or executable form under the terms of
# Sections 1 and 2 above provided that you also do one of the following:
# 
#     a) Accompany it with the complete corresponding machine-readable
#     source code, which must be distributed under the terms of Sections
#     1 and 2 above on a medium customarily used for software interchange; or,
# 
#     b) Accompany it with a written offer, valid for at least three
#     years, to give any third party, for a charge no more than your
#     cost of physically performing source distribution, a complete
#     machine-readable copy of the corresponding source code, to be
#     distributed under the terms of Sections 1 and 2 above on a medium
#     customarily used for software interchange; or,
# 
#     c) Accompany it with the information you received as to the offer
#     to distribute corresponding source code.  (This alternative is
#     allowed only for noncommercial distribution and only if you
#     received the program in object code or executable form with such
#     an offer, in accord with Subsection b above.)
# 
# The source code for a work means the preferred form of the work for
# making modifications to it.  For an executable work, complete source
# code means all the source code for all modules it contains, plus any
# associated interface definition files, plus the scripts used to
# control compilation and installation of the executable.  However, as a
# special exception, the source code distributed need not include
# anything that is normally distributed (in either source or binary
# form) with the major components (compiler, kernel, and so on) of the
# operating system on which the executable runs, unless that component
# itself accompanies the executable.
# 
# If distribution of executable or object code is made by offering
# access to copy from a designated place, then offering equivalent
# access to copy the source code from the same place counts as
# distribution of the source code, even though third parties are not
# compelled to copy the source along with the object code.
# 
#   4. You may not copy, modify, sublicense, or distribute the Program
# except as expressly provided under this License.  Any attempt
# otherwise to copy, modify, sublicense or distribute the Program is
# void, and will automatically terminate your rights under this License.
# However, parties who have received copies, or rights, from you under
# this License will not have their licenses terminated so long as such
# parties remain in full compliance.
# 
#   5. You are not required to accept this License, since you have not
# signed it.  However, nothing else grants you permission to modify or
# distribute the Program or its derivative works.  These actions are
# prohibited by law if you do not accept this License.  Therefore, by
# modifying or distributing the Program (or any work based on the
# Program), you indicate your acceptance of this License to do so, and
# all its terms and conditions for copying, distributing or modifying
# the Program or works based on it.
# 
#   6. Each time you redistribute the Program (or any work based on the
# Program), the recipient automatically receives a license from the
# original licensor to copy, distribute or modify the Program subject to
# these terms and conditions.  You may not impose any further
# restrictions on the recipients' exercise of the rights granted herein.
# You are not responsible for enforcing compliance by third parties to
# this License.
# 
#   7. If, as a consequence of a court judgment or allegation of patent
# infringement or for any other reason (not limited to patent issues),
# conditions are imposed on you (whether by court order, agreement or
# otherwise) that contradict the conditions of this License, they do not
# excuse you from the conditions of this License.  If you cannot
# distribute so as to satisfy simultaneously your obligations under this
# License and any other pertinent obligations, then as a consequence you
# may not distribute the Program at all.  For example, if a patent
# license would not permit royalty-free redistribution of the Program by
# all those who receive copies directly or indirectly through you, then
# the only way you could satisfy both it and this License would be to
# refrain entirely from distribution of the Program.
# 
# If any portion of this section is held invalid or unenforceable under
# any particular circumstance, the balance of the section is intended to
# apply and the section as a whole is intended to apply in other
# circumstances.
# 
# It is not the purpose of this section to induce you to infringe any
# patents or other property right claims or to contest validity of any
# such claims; this section has the sole purpose of protecting the
# integrity of the free software distribution system, which is
# implemented by public license practices.  Many people have made
# generous contributions to the wide range of software distributed
# through that system in reliance on consistent application of that
# system; it is up to the author/donor to decide if he or she is willing
# to distribute software through any other system and a licensee cannot
# impose that choice.
# 
# This section is intended to make thoroughly clear what is believed to
# be a consequence of the rest of this License.
# 
#   8. If the distribution and/or use of the Program is restricted in
# certain countries either by patents or by copyrighted interfaces, the
# original copyright holder who places the Program under this License
# may add an explicit geographical distribution limitation excluding
# those countries, so that distribution is permitted only in or among
# countries not thus excluded.  In such case, this License incorporates
# the limitation as if written in the body of this License.
# 
#   9. The Free Software Foundation may publish revised and/or new versions
# of the General Public License from time to time.  Such new versions will
# be similar in spirit to the present version, but may differ in detail to
# address new problems or concerns.
# 
# Each version is given a distinguishing version number.  If the Program
# specifies a version number of this License which applies to it and "any
# later version", you have the option of following the terms and conditions
# either of that version or of any later version published by the Free
# Software Foundation.  If the Program does not specify a version number of
# this License, you may choose any version ever published by the Free Software
# Foundation.
# 
#   10. If you wish to incorporate parts of the Program into other free
# programs whose distribution conditions are different, write to the author
# to ask for permission.  For software which is copyrighted by the Free
# Software Foundation, write to the Free Software Foundation; we sometimes
# make exceptions for this.  Our decision will be guided by the two goals
# of preserving the free status of all derivatives of our free software and
# of promoting the sharing and reuse of software generally.
# 
# 			    NO WARRANTY
# 
#   11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
#   12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# 		     END OF TERMS AND CONDITIONS
#
# 	    How to Apply These Terms to Your New Programs
# 
#   If you develop a new program, and you want it to be of the greatest
# possible use to the public, the best way to achieve this is to make it
# free software which everyone can redistribute and change under these terms.
# 
#   To do so, attach the following notices to the program.  It is safest
# to attach them to the start of each source file to most effectively
# convey the exclusion of warranty; and each file should have at least
# the "copyright" line and a pointer to where the full notice is found.
# 
#     <one line to give the program's name and a brief idea of what it does.>
#     Copyright (C) 19yy  <name of author>
# 
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
# 
# 
# Also add information on how to contact you by electronic and paper mail.
# 
# If the program is interactive, make it output a short notice like this
# when it starts in an interactive mode:
# 
#     Gnomovision version 69, Copyright (C) 19yy name of author
#     Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
#     This is free software, and you are welcome to redistribute it
#     under certain conditions; type `show c' for details.
# 
# The hypothetical commands `show w' and `show c' should show the appropriate
# parts of the General Public License.  Of course, the commands you use may
# be called something other than `show w' and `show c'; they could even be
# mouse-clicks or menu items--whatever suits your program.
# 
# You should also get your employer (if you work as a programmer) or your
# school, if any, to sign a "copyright disclaimer" for the program, if
# necessary.  Here is a sample; alter the names:
# 
#   Yoyodyne, Inc., hereby disclaims all copyright interest in the program
#   `Gnomovision' (which makes passes at compilers) written by James Hacker.
# 
#   <signature of Ty Coon>, 1 April 1989
#   Ty Coon, President of Vice
# 
# This General Public License does not permit incorporating your program into
# proprietary programs.  If your program is a subroutine library, you may
# consider it more useful to permit linking proprietary applications with the
# library.  If this is what you want to do, use the GNU Library General
# Public License instead of this License.
# 

#
# The program starts here.
#

($me = $0) =~ s,^.*/,,;

#  Initial (default) values of parameters

$datafile = '';		# Input file
$finishthresh = 0.005;	# Minimum improvement in the cost per input word type
			# that an epoch must produce in order for a new
			# epoch to start. During an epoch all input words
                        # are processed once (not guaranteed if -savememory
                        # is in use).
$randseed = 0;		# Random seed
$maxskip = 8;		# Maximum number of skips when picking next word
			# to process (only applies to -savememory).
$savememory = 0;	# Use less memory (default = off)
$usegammalendistr = 0;	# Whether to use a Gamma pdf prior for morph lengths
$mostcommonmorphlen = 7.0;
			# Prior for most common morph length in lexicon
$beta = 1.0;		# Beta value in Gamma pdf
$usezipffreqdistr = 0;	# Whether to use a Zipfian pdf prior morph morph
			# frequencies
$hapax = 0.5;	        # Prior for proportion of morphs that only occur once
			# in the corpus.
$modelfile = '';	# File from which an existing model is loaded
$trace = 0;		# Trace progress of program

# Read command line parameters

while ($arg = shift @ARGV) {
    if ($arg eq "-data") {
	$datafile = shift @ARGV;
    }
    elsif ($arg eq "-finish") {
	$finishthresh = shift @ARGV;
	&usage() unless (($finishthresh =~ /^[\.0-9]+$/) && 
			 ($finishthresh > 0) && 
			 ($finishthresh < 1));
    }
    elsif ($arg eq "-rand") {
	$randseed = shift @ARGV;
	&usage() unless ($randseed =~ /^[0-9]+$/);
    }
    elsif ($arg eq "-savememory") {
	$savememory = 1;
	$arg = shift @ARGV;
	if ($arg =~ /^[0-9]+$/) {
	    $maxskip = $arg;
	}
	else {
	    unshift @ARGV, $arg if (defined $arg);
	}
    }
    elsif ($arg eq "-gammalendistr") {
	$usegammalendistr = 1;
	$arg = shift @ARGV;
	if ($arg =~ /^[\.0-9]+$/) {
	    $mostcommonmorphlen = $arg;
	    &usage() unless ($mostcommonmorphlen > 0);
	    $arg = shift @ARGV;
	    if ($arg =~ /^[\.0-9]+$/) {
		$beta = $arg;
		&usage() unless ($beta > 0);
	    }
	    else {
		unshift @ARGV, $arg if (defined $arg);
	    }
	}
	else {
	    unshift @ARGV, $arg if (defined $arg);
	}
    }
    elsif ($arg eq "-zipffreqdistr") {
	$usezipffreqdistr = 1;
	$arg = shift @ARGV;
	if ($arg =~ /^[\.0-9]+$/) {
	    $hapax = $arg;
	    &usage() unless (($hapax > 0) && ($hapax < 1));
	}
	else {
	    unshift @ARGV, $arg if (defined $arg);
	}
    }
    elsif ($arg eq "-load") {
	$modelfile = shift @ARGV;
	&usage() unless ($modelfile);
    }
    elsif ($arg eq "-trace") {
	$trace = shift @ARGV;
	&usage() unless ($trace =~ /^[0-9]+$/);
    }
    else {
	&usage();
    }
}

&usage unless ($datafile);

$starttime = time;
srand($randseed);

%morphinfo = ();	# Morph & word info. For more info: See
			# subroutine &initmodel().
$nlines = 0;		# Number of input lines read

if ($trace & 1) {
    $| = 1;		# Flush output
}

&printheader(\*STDOUT);

if ($modelfile) {  # Segment words according to an existing model

    # Load the model
    &loadmodel();
    
    # Do the segmentation
    open(DATA, $datafile) ||
	die "Error ($me): Unable to open file \"$datafile\" for reading.\n";

    while ($line = <DATA>) {
	($wcount, $word) = &readword($line);
	my(@morphs) = &viterbisegmentword($word);
	print "$wcount " if ($wcount);
	print join(' + ', @morphs) . "\n";
    }
    close DATA;

}

else {	# Learn a new segmentation model from the data

    # Read words from input

    open(DATA, $datafile) ||
	die "Error ($me): Unable to open file \"$datafile\" for reading.\n";

    while ($line = <DATA>) {
	($wcount, $word) = &readword($line);

	# Update word counts:
	# $morphinfo contains a word count at this point:
	$morphinfo{$word} += $wcount;

	if ($trace & 2) {
	    $nlines++;
	    print "# Read $nlines lines from input...\n"
		unless ($nlines % 50000);
	}
    }
    close DATA;

    # Initialize model variables
    &initmodel();

    # Split words until the overall logprob converges
    &processwords();

    &outputmorphlengthdistribution() if ($trace & 16);

    # Output the split vocabulary

    open(DATA, $datafile) ||
	die "Error ($me): Unable to open file \"$datafile\" for reading.\n";
    
    print "# Vocabulary:\n";
    while ($line = <DATA>) {
	($wcount, $word) = &readword($line);
	$wcount = &resetwordcount($word);
	if ($wcount) {
	    my(@morphs) = &expandmorph($word);
	    print "$wcount " . join(' + ', @morphs) . "\n";
	}
    }
    close DATA;
}

$totaltime = time - $starttime;

print "# Time used (secs): $totaltime\n";

# End.

# Print header, i.e., the command line parameters, starting time etc.

sub printheader {

    my($filedescr) = shift @_;

    # Print header
    print $filedescr "# $0, " . localtime() . "\n";
    print $filedescr "# Working dir: " . `pwd`;
    print $filedescr "# -data '$datafile'\n";
    print $filedescr "# -finish $finishthresh\n";
    print $filedescr "# -rand $randseed\n";
    if ($savememory) {
	print $filedescr "# -savememory $maxskip\n";
    }
    else {
	print $filedescr "# -savememory: OFF\n";
    }
    if ($usegammalendistr) {
	print $filedescr "# -gammalendistr $mostcommonmorphlen $beta\n";
    }
    else {
	print $filedescr "# -gammalendistr: OFF\n";
    }
    if ($usezipffreqdistr) {
	print $filedescr "# -zipffreqdistr $hapax\n";
    }
    else {
	print $filedescr "# -zipffreqdistr: OFF\n";
    }
    if ($modelfile) {
	print $filedescr "# -load '$modelfile'\n";
    }
    else {
	print $filedescr "# -load: OFF\n";
    }
    print $filedescr "# -trace $trace\n";
}

# Extracts the word and word count from a line of input

sub readword {
    my($line) = shift @_;
    my($wcount, $word);

    chomp $line;
    if ($line =~ /^[ \t]*([0-9]+)[ \t](.+)$/) {
	$wcount = $1;
	$word = $2;
    }
    else {
	$wcount = 1;
	$word = $line;
    }
    $word =~ tr/ \r\t//d;

    return ($wcount, $word);
}

# Initialize model variables

sub initmodel {

    # Global variables

    $log2coeff = 1/log(2);  # Coeff. for conversion to log2
    $nwordtokens = 0;	    # Number of word tokens in input data
    $nwordtypes = 0;	    # Number of word types in input data
    $maxwordlen = 0;	    # Longest word in the input
    %letterlogprob = ();    # Probability distr. of letters as estimated
			    # from input data. 
    $nmorphtokens = 0;	    # Total number of occurrences of all morph
			    # tokens in the corpus.
    $nmorphtypes = 0;	    # Total number of morphs in the lexicon, which
			    # equals the number of morph types in the corpus.
    $logtokensum = 0;	    # Part of the coding length of the corpus
    $nvirtualmorphtypes = 0;# Number of different morphs (type count),
			    # either virtual (=split) morphs or
			    # real (=unsplit) morphs
    @randomwords = ();	    # List containing words sorted by random
    $nlettertokens = 0;	    # Number of letters in lexicon
    $corpusmorphcost = 0;   # Code length of morph pointers in corpus
    $morphstringscost = 0;  # Code length of spelling out the morphs in the
			    # lexicon
    $lendistrcost = 0;	    # Cost of coding the morph lengths
    $freqdistrcost = 0;	    # Cost of coding the morph frequencies
    $factorialnmorphtypes = 0;
                            # If free order in lexicon: Subtract this from cost

    $log2hapax = log(1 - $hapax)/log(2);     # Precalculated value
    
    my($word, $wcount, $wlen, $letter);
    my($ncorpuslettertokens) = 0;	# Number of letters in input

    while (($word, $wcount) = each %morphinfo) {

	# Update word counts
	$nwordtokens += $wcount;
	$nwordtypes++;

	# Update maximum word length
	$wlen = length($word);
	$maxwordlen = $wlen if ($wlen > $maxwordlen);

	# Compute frequencies (i.e., counts) of each letter in the data
	#
	unless ($usegammalendistr) {
	    $word .= " "; # Append word break
	    $wlen++;
	}

	foreach $letter (split(//, $word)) {
	    # The variable name $letterlogprob is misleading at this
	    # stage, when it contains counts of occurrences of letters:
	    $letterlogprob{$letter} += $wcount;
	}

	# Total number of letters in the corpus, including word breaks
	$ncorpuslettertokens += $wcount*$wlen;

    }

    # Convert letter frequencies to negative logprobs
    my($logncorpuslettertokens) = log($ncorpuslettertokens);
    foreach $letter (keys %letterlogprob) {
	$letterlogprob{$letter} =
	    $logncorpuslettertokens - log($letterlogprob{$letter});
    }

    # Diagnostic output of letter logprobs:
    if ($trace & 2) {
	my($tmp) = "incl.";
	$tmp = "excl." if ($usegammalendistr);
	print "# Number of letters in corpus ($tmp word breaks): " . 
	    $ncorpuslettertokens . "\n";
	print "# Letter logprobs (log2):\n";
	foreach $letter (sort keys %letterlogprob) {
	    printf("# %s -> %.5f\n", $letter,
		   $log2coeff*$letterlogprob{$letter});
	}
    }

    # Make a table of log gamma pdf values
    &initloggammapdf() if ($usegammalendistr);

    # From now on, %morphinfo contains the following information:
    # %morphinfo is a hash, whose keys are morph strings, and the
    # values are strings of the format:
    # <word count><SPACE><morph count><SPACE><split location>
    # The word count is the number of occurrences of the word in the
    # input data (if this morph occurs as an entire word).
    # The morph count tells how many times the particular morph exists
    # in the segmentation of the input data.
    # If the split location is zero, the morph is not split, i.e., it
    # really exists as a morph in the morph set.
    # If the split location is greater than zero, the morph has been split
    # after the character indicated by the split location (through
    # recursive splitting).
    # All morphs have morph counts, even if they are split. This
    # makes it possible to trace how greater chunks have been split into
    # smaller chunks, which enables us to resplit badly split morphs.

    while (($word, $wcount) = each %morphinfo) {
	$morphinfo{$word} = "";
	&increasemorphcount($word, $wcount);	 # Update morph count
	$morphinfo{$word} = "$wcount $wcount 0"; # Update word count
    }

}

# Process the words, i.e., optimize the model until convergence
# of the overall logprob (or code length)

sub processwords {

    my($oldcost) = 0;
    my($newcost) = &gettotalcost();
    my($word);

    &printcost($newcost) if ($trace & 2);

    do {

	foreach $i (1 .. $nwordtypes) {
	    $word = &getnextrandomword();
	    &resplitnode($word);

	    if ($trace & 4) {
		my(@morphs) = &expandmorph($word);
		print "# $word (\#$i): " . join(' + ', @morphs) . "\n";
	    }
	    if ($trace & 2) {
		print "# Processed $i words...\n" unless ($i % 50000);
	    }

	}

	$oldcost = $newcost;
	$newcost = &gettotalcost();
	&printcost($newcost) if ($trace & 2);

    } while ($newcost < $oldcost - $finishthresh*$nwordtypes);
						   # Iterate until no
						   # substantial improvement
    &resetnextrandomword();
    print "# Done...\n" if ($trace & 2);
}

# Print progress report during processing (if trace on)

sub printcost {

    my($cost) = shift @_;

    printf("#\n");
    printf("# OVERALL logprob: %.0f\n", $cost);
    printf("# NMorphTokens: %d, ", $nmorphtokens);
    printf("NMorphTypes: %d, ", $nmorphtypes);
    printf("NVirtualMorphTypes: %d\n", $nvirtualmorphtypes);
    printf("# NWordTokens: %d, ", $nwordtokens);
    printf("NWordTypes: %d\n", $nwordtypes);
    printf("# CORPUS: %0.f\n", $log2coeff*$corpusmorphcost);
    printf("# LEXICON: %0.f; ",
	   $log2coeff*($morphstringscost + $lendistrcost +
		       $freqdistrcost + $factorialnmorphtypes));
    printf("Str: %.0f, ", $log2coeff*$morphstringscost);
    printf("LenD: %.0f, ", $log2coeff*$lendistrcost);
    printf("FreqD: %.0f, ", $log2coeff*$freqdistrcost);
    printf("FreeO: %.0f\n", $log2coeff*$factorialnmorphtypes);
}

# Split a morph recursively

sub resplitnode {

    my($morph) = shift @_;

    # Remove the morph (and its subtree):
    my($wcount, $mcount) = &removemorph($morph);

    # Put it back as an unsplit morph
    &increasemorphcount($morph, $mcount);
    my($mincost) = &gettotalcost();	   # Compute cost
    &increasemorphcount($morph, -$mcount); # Remove morph again
    
    # Try other segmentations
    my($splitlocation) = 0;
    my($i, $cost, $prefix, $suffix, $newnmorphtokens);
    foreach $i (1 .. length($morph)-1) {
	$prefix = substr($morph, 0, $i);
	$suffix = substr($morph, $i);
	&increasemorphcount($prefix, $mcount);  # Add two submorphs
	&increasemorphcount($suffix, $mcount);  #
	$cost = &gettotalcost();                # Compute cost
	&increasemorphcount($prefix, -$mcount); # And remove the
	&increasemorphcount($suffix, -$mcount); # submorphs
	if ($cost <= $mincost) {
	    $mincost = $cost;
	    $splitlocation = $i;
	}
    }

    # Choose the segmentation (or no segmentation) with the lowest cost
    #
    if ($splitlocation) {	# Virtual morph (a split morph)
	$nvirtualmorphtypes++ unless ($morphinfo{$morph});
	$morphinfo{$morph} = "$wcount $mcount $splitlocation";

	# Add submorphs as real (unsplit) morphs
	$prefix = substr($morph, 0, $splitlocation);
	$suffix = substr($morph, $splitlocation);
	&increasemorphcount($prefix, $mcount);
	&increasemorphcount($suffix, $mcount);
	print "# $morph --split--> $prefix + $suffix\n" if ($trace & 8);

	# Recursive split of the submorphs
	&resplitnode($prefix);
	&resplitnode($suffix);
    }
    else {	# Real morph (no split)
	$morphinfo{$morph} = "$wcount 0 0";
	&increasemorphcount($morph, $mcount);
	print "# $morph --no-split--> $morph\n" if ($trace & 8);
    }
}

# Remove a morph and update counts for its submorphs.
# Returns the word count and the number of morph occurrences removed.

sub removemorph {
    my($morph, @crap) = @_;
    die "Error ($me): Assertion failed (removemorph).\n"
	unless ($morphinfo{$morph});

    my($wcount, $mcount, $splitlocation) = split(' ', $morphinfo{$morph});
    &increasemorphcount($morph, -$mcount);
    return ($wcount, $mcount);
}

# Increase counts for a morph and all its submorphs

sub increasemorphcount {

    my($morph) = shift @_;
    my($deltacount) =  shift @_;

    my($wcount, $mcount, $splitlocation);
    if ($morphinfo{$morph}) {
	($wcount, $mcount, $splitlocation) = split(' ', $morphinfo{$morph});
    }
    else {
	($wcount, $mcount, $splitlocation) = (0, 0, 0);
    }

    my($newmcount) = $mcount + $deltacount;
    die "Error ($me): Assertion failed (increasemorphcount): " .
	"Negative morph count.\n" if ($newmcount < 0);

    if ($newmcount == 0) {
	delete $morphinfo{$morph};
	$nvirtualmorphtypes--;
    }
    else {
	$morphinfo{$morph} = "$wcount $newmcount $splitlocation";
	$nvirtualmorphtypes++ if ($mcount == 0);
    }

    if ($splitlocation) {
	# Recursively propagate new count to submorphs
	my($prefix) = substr($morph, 0, $splitlocation);
	my($suffix) = substr($morph, $splitlocation);
	&increasemorphcount($prefix, $deltacount);
	&increasemorphcount($suffix, $deltacount);
    }
    else { # This morph has no submorphs, i.e., it is a real morph
	   # with associative cost (coding length)

	$nmorphtokens += $deltacount;

	# Decrease old count
	if ($mcount > 0) {

	    my($logmcount) = log($mcount);

	    # Morph pointers in corpus
	    $logtokensum -= $mcount*$logmcount;

	    # Zipfian length cost
	    if ($usezipffreqdistr) {
		$freqdistrcost -= 
		    -log($mcount**$log2hapax - ($mcount+1)**$log2hapax);
	    }
	}

	# Increase new count
	if ($newmcount > 0) {

	    my($lognewmcount) = log($newmcount);

	    # Morph pointers in corpus
	    $logtokensum += $newmcount*$lognewmcount;

	    # Zipfian length cost
	    if ($usezipffreqdistr) {
		$freqdistrcost += 
		    -log($newmcount**$log2hapax - ($newmcount+1)**$log2hapax);
	    }

	}

	if ((($mcount == 0) && ($newmcount > 0)) || # A morph type was
	    (($newmcount == 0) && ($mcount > 0))) { # added or removed
                                                    # from the lexicon
	    my($sign) = 0;
	    if ($newmcount == 0) {
		$sign = -1;	# Morph type removed
	    }
	    else {
		$sign = 1;	# Morph type added
	    }

	    $nmorphtypes += $sign;

	    # Add or remove letters from the lexicon
	    #
	    my($morphlen) = length($morph);

	    # Encode morph length...
	    #
	    if ($usegammalendistr) {
		# Gamma length distribution
		$lendistrcost += $sign*$loggammapdf[$morphlen];
	    }
	    else {
		# End-of-morph character used instead of
		# explicit length distribution
		$lendistrcost += $sign*$letterlogprob{' '};
		$morphlen++;
	    }

	    # Number of letters/characters in lexicon:
	    $nlettertokens += $sign*$morphlen;

	    # ... and add or remove the letters
	    my(@letters) = split(//, $morph);
	    foreach $letter (@letters) {
		$morphstringscost += $sign*$letterlogprob{$letter};
	    }
	}
    }
}


# Retrieve the overall logprob, or equivalently code length,
# of the lexicon and the corpus. The negative of the logprobs
# (which are negative or zero) are taken, i.e., all costs or
# logprobs are non-negative in this program!
#
sub gettotalcost { 

    # Logprob (or code length) of the corpus, i.e., morph pointers
    # to entries in the lexicon. 

    my($ntotalmorphtokens) = $nmorphtokens;
    my($ntotalmorphtypes) = $nmorphtypes;
    my($logntotalmorphtokens) = log($ntotalmorphtokens);
    
    # Code length of morphs:
    $corpusmorphcost = $nmorphtokens*$logntotalmorphtokens - $logtokensum;

    # Free order of morphs in lexicon
    # log n! approx = n * log(n - 1)
    $factorialnmorphtypes = $nmorphtypes*(1 - log($nmorphtypes));

    # Enumerative morph frequency distribution (if not Zipfian)
    #
    unless ($usezipffreqdistr) {
	$freqdistrcost = 0;
	$freqdistrcost += ($ntotalmorphtokens - 1)*log($ntotalmorphtokens - 2)
	    if ($ntotalmorphtokens > 2);
	$freqdistrcost -= ($ntotalmorphtypes - 1)*log($ntotalmorphtypes - 2)
	    if ($ntotalmorphtypes > 2);
	$freqdistrcost -= ($ntotalmorphtokens - $ntotalmorphtypes)
	    *log($ntotalmorphtokens - $ntotalmorphtypes - 1)
		if ($ntotalmorphtokens - $ntotalmorphtypes > 1);
    }

    # Overall cost
    return
	$log2coeff*($corpusmorphcost + $morphstringscost + $lendistrcost
		    + $freqdistrcost + $factorialnmorphtypes);
}

# Return a list of which morphs a particular morph consists of

sub expandmorph {
    my($morph) = shift @_;
    my($wcount, $mcount, $splitlocation) = split(' ', $morphinfo{$morph});
    my(@morphs) = ();
    if ($splitlocation) {
	my($prefix) = substr($morph, 0, $splitlocation);
	my($suffix) = substr($morph, $splitlocation);
	push @morphs, &expandmorph($prefix);
	push @morphs, &expandmorph($suffix);
    }
    else {
	push @morphs, $morph;
    }
    return @morphs;
}

# Returns and resets the word count of a word, i.e. make it invisible
# as a word in the future (e.g., in order not to print the segmentation
# of the same word many times)

sub resetwordcount {
    my($word) = shift @_;

    unless ($morphinfo{$word}) {
	die "Error ($me): Assertion failed (resetwordcount).\n";
    }

    my($wcount, $mcount, $msplit) = split(' ', $morphinfo{$word});
    $morphinfo{$word} = "0 $mcount $msplit";
    return $wcount;
}

# Find next word to process. The selection is done by random.

sub getnextrandomword {

    if ($savememory) {

	# Save memory. Pick words from the %morphinfo hash by random.
	#
	# First, skip a random number of items, so that the next word is not
	# deterministically chosen.
	#
	# Note that %morphinfo IS modified between calls to 'each', which
	# means that the same item may show up many times before the hash
	# is consumed. But that should not be a problem for us.
	my($skip) = rand($maxskip);
	my($i, $word, $info, $wcount, @crap);
	foreach $i (1 .. $skip) {
	    @crap = each %morphinfo;
	}
    
	# Then pick the next item that is really a word
	my($done) = 0;
	do {
	    ($word, $info) = each %morphinfo;
	    if ($info) {
		($wcount, @crap) = split(' ', $info);
		$done = $wcount;
	    }
	} while (!$done);
    
	return $word;
    }

    # Else don't save memory. This means that we can copy up the words
    # in the %morphinfo hash into a randomly sorted wordlist.

    unless (@randomwords) {
	# @randomwords was empty. Generate a new wordlist by random.
	# First collect the words into a list:
	my($word, $info, $wcount, $i, $j, $tmp, @crap);
	while (($word, $info) = each %morphinfo) {
	    ($wcount, @crap) = split(' ', $info);
	    if ($wcount) {
		# Only accept words, not morphs
		push @randomwords, $word;
	    }
	}
	# Sort the words into random order
	for ($i = scalar(@randomwords) - 1; $i > 0; $i--) {
	    # $j = Random value [0, 1, .., $i]
	    $j = sprintf("%d", rand($i + 1));
	    $tmp = $randomwords[$i];
	    $randomwords[$i] = $randomwords[$j];
	    $randomwords[$j] = $tmp;
	}
    }

    # Return the next word in the word list sorted by random
    return shift @randomwords;
}

sub resetnextrandomword {

    if ($savememory) {
	# Reset the pointer to the first item in %morphinfo
	while (each %morphinfo) {
	}
    }
    else {
	# Clear randomly sorted word list
	@randomwords = ();
    }
}

# Make a table of precalculated log Gamma PDF values to be used
# as the morph length prior distribution

sub initloggammapdf {
    # This is a global variable!
    @loggammapdf = ();

    # The alpha value of the Gamma pdf is found from the
    # maximum value of the density ($mostcommonmorphlen) like this:
    my($alpha) = $mostcommonmorphlen/$beta + 1;

    my($i);
    foreach $i (1 .. $maxwordlen) {
	$loggammapdf[$i] = &getloggammapdf($i, $alpha, $beta);
    }
}

# Gamma pdf values

sub getloggammapdf {
    my($x, $alpha, $beta, @crap) = @_;

    # Round alpha to the closest 0.05
    my($roundedalpha) = sprintf('%.0f', 20*$alpha)/20;

    die "Error ($me): Too high float1 value given through the " .
	"-gammalendistr float1 float2 option.\n" if ($alpha > 25);

    # Return logGamma density value, i.e., the negative natural
    # logarithm of the probability
    return
	log(&gammafunc($roundedalpha)) + $roundedalpha*log($beta)
	- ($roundedalpha - 1)*log($x) + $x/$beta;
}

sub gammafunc {
    my($alpha, @crap) = @_;

    # 500 Gamma function values for alpha = 0.05, 0.1, 0.15, ..., 24.95, 25.0
    my(@gammas) =
	(19.470085, 9.513508, 6.220273, 4.590844, 3.625610, 2.991569,
	2.546147, 2.218160, 1.968136, 1.772454, 1.616124, 1.489192,
	1.384795, 1.298055, 1.225417, 1.164230, 1.112484, 1.068629,
	1.031453, 1.000000, 0.973504, 0.951351, 0.933041, 0.918169,
	0.906402, 0.897471, 0.891151, 0.887264, 0.885661, 0.886227,
	0.888868, 0.893515, 0.900117, 0.908639, 0.919063, 0.931384,
	0.945611, 0.961766, 0.979881, 1.000000, 1.022179, 1.046486,
	1.072997, 1.101802, 1.133003, 1.166712, 1.203054, 1.242169,
	1.284209, 1.329340, 1.377746, 1.429625, 1.485193, 1.544686,
	1.608359, 1.676491, 1.749381, 1.827355, 1.910767, 2.000000,
	2.095468, 2.197620, 2.306944, 2.423965, 2.549257, 2.683437,
	2.827178, 2.981206, 3.146312, 3.323351, 3.513252, 3.717024,
	3.935761, 4.170652, 4.422988, 4.694174, 4.985735, 5.299330,
	5.636763, 6.000000, 6.391177, 6.812623, 7.266873, 7.756690,
	8.285085, 8.855343, 9.471046, 10.136102, 10.854777, 11.631728,
	12.472045, 13.381286, 14.365527, 15.431412, 16.586207,
	17.837862, 19.195079, 20.667386, 22.265216, 24.000000,
	25.884268, 27.931754, 30.157522, 32.578096, 35.211612,
	38.077976, 41.199051, 44.598848, 48.303756, 52.342778,
	56.747805, 61.553915, 66.799700, 72.527635, 78.784481,
	85.621738, 93.096135, 101.270191, 110.212817, 120.000000,
	130.715552, 142.451944, 155.311236, 169.406099, 184.860962,
	201.813275, 220.414921, 240.833780, 263.255469, 287.885278,
	314.950319, 344.701924, 377.418304, 413.407517, 453.010766,
	496.606078, 544.612392, 597.494128, 655.766263, 720.000000,
	790.829087, 868.956859, 955.164101, 1050.317817, 1155.381014,
	1271.423634, 1399.634749, 1541.336192, 1697.997776,
	1871.254306, 2062.924591, 2275.032699, 2509.831722,
	2769.830362, 3057.822671, 3376.921328, 3730.594887,
	4122.709484, 4557.575527, 5040.000000, 5575.345061,
	6169.593697, 6829.423323, 7562.288280, 8376.512351,
	9281.392526, 10287.315405, 11405.887820, 12650.083429,
	14034.407293, 15575.080662, 17290.248510, 19200.212672,
	21327.693790, 23698.125702, 26339.986355, 29285.169865,
	32569.404926, 36232.725438, 40320.000000, 44881.527739,
	49973.708950, 55659.800086, 62010.763896, 69106.226895,
	77035.557964, 85899.083634, 95809.457688, 106893.204979,
	119292.461995, 133166.939659, 148696.137183, 166081.839609,
	185550.935972, 207358.599890, 231791.879920, 259173.753304,
	289867.703840, 324282.892674, 362880.000000, 406177.826035,
	454760.751442, 509287.170788, 570499.027841, 639232.598780,
	716430.689062, 803156.431977, 900608.902268, 1010140.787047,
	1133278.388949, 1271744.273742, 1427482.916953,
	1602689.752224, 1799844.078931, 2021746.348930,
	2271560.423213, 2552861.470046, 2869690.268017,
	3226614.782105, 3628800.000000, 4082087.151650,
	4593083.589560, 5169264.783501, 5819090.083979,
	6552134.137491, 7379236.097342, 8312669.070964,
	9366332.583592, 10555971.224644, 11899423.083962,
	13416902.087980, 15131318.919703, 17068645.861181,
	19258331.644566, 21733773.250997, 24532852.570698,
	27698546.949994, 31279623.921386, 35331431.864048,
	39916800.000000, 45107063.025737, 50983227.844116,
	57637302.336040, 65173808.940560, 73711509.046770,
	83385367.899970, 94348793.955445, 106776191.452949,
	120865870.522178, 136843365.465566, 154965219.116173,
	175523299.468557, 198849724.282764, 225322480.241420,
	255371835.699212, 289487660.334242, 328227781.357427,
	372227524.664496, 422210610.775375, 479001600.000000,
	543540109.460129, 616897056.913805, 700293223.382880,
	795120469.074830, 902965985.822930, 1025640025.169627,
	1165207605.349734, 1324024774.016567, 1504780088.001107,
	1710542068.319572, 1944813499.907959, 2211593573.303810,
	2515449012.176946, 2861595499.066012, 3255990905.164941,
	3705442052.278275, 4217726990.442922, 4801735068.171977,
	5467627409.541089, 6227020800.000000, 7093198428.454687,
	8081351445.570852, 9208855887.484869, 10495590191.787739,
	11964299312.153851, 13641012334.756020, 15555521531.419006,
	17741931971.821926, 20239292183.614841, 23092317922.314262,
	26352222923.752903, 30077672596.931820, 34335879016.215420,
	39203858337.204430, 44769874946.017982, 51135100321.440285,
	58415518817.634346, 66744117447.590508, 76273402363.098083,
	87178291200.000000, 99659437919.788193, 113947055382.549515,
	130305310807.910751, 149037380723.385864, 170491265198.192200,
	195066476387.011841, 223221733975.861938, 255483820394.235229,
	292457772053.235168, 334838609873.556396, 383424843540.602722,
	439134019915.202454, 503020627587.555969, 576296717556.903320,
	660355655453.767090, 756799484757.316528, 867470454441.869263,
	994487349969.107178, 1140287365328.316406,
	1307674368000.000000, 1499874540692.826172,
	1720600536276.478760, 1974125458739.857178,
	2265368186995.462891, 2599991794272.428711,
	2984517088721.292969, 3426453616529.469238,
	3934450834071.240723, 4518472578222.475586,
	5189998453040.109375, 5962256317056.411133,
	6850490710677.132812, 7872272821745.204102,
	9047858465643.433594, 10400601573396.800781,
	11957431859165.662109, 13749406702903.582031,
	15812348864508.619141, 18187583476986.574219,
	20922789888000.000000, 24072986378119.742188,
	27701668634051.332031, 31882126158648.394531,
	36698964629326.445312, 42249866656927.203125,
	48647628546157.062500, 56022516630256.812500,
	64524993678768.125000, 74328873911759.703125,
	85634974475162.218750, 98675342047283.656250,
	113718145797240.328125, 131073342482058.671875,
	151099236376244.812500, 174210076354395.562500,
	200884855233982.531250, 231677502943924.218750,
	267228695810196.062500, 308279539934923.062500,
	355687428096000.000000, 410444417746943.750000,
	473698533642277.437500, 546778463620823.437500,
	631222191624418.375000, 728810199831989.875000,
	841603973848514.375000, 971990663534962.375000,
	1122734890010564.250000, 1297038849760207.500000,
	1498612053315332.500000, 1731752252929828.500000,
	2001439366031453.500000, 2313444494808328.000000,
	2674456483859532.000000, 3092228855290529.000000,
	3575750423164910.000000, 4135443427549118.000000,
	4783393655002521.000000, 5533617741831885.000000,
	6402373705728000.000000, 7408521740332310.000000,
	8573943458925345.000000, 9924029114717896.000000,
	11488243887564482.000000, 13300786146933880.000000,
	15401352721427748.000000, 17836028675866656.000000,
	20658321976194400.000000, 23930366778075924.000000,
	27724322986333636.000000, 32124004291848476.000000,
	37226772208185208.000000, 43145739828175320.000000,
	50012336248172888.000000, 57979291036697392.000000,
	67224107955500056.000000, 77953108609300928.000000,
	90406140079548048.000000, 104862056207714000.000000,
	121645100408832000.000000, 141132339153329984.000000,
	163762320065474208.000000, 190045157546848256.000000,
	220574282641237408.000000, 256040133328477248.000000,
	297246107523557824.000000, 345127154878020672.000000,
	400771446338173120.000000, 465445633833574720.000000,
	540624298233507200.000000, 628024283905635328.000000,
	729644735280427008.000000, 847813787623647744.000000,
	985243024089014400.000000, 1145090997974782336.000000,
	1331037337518903040.000000, 1547369205894622208.000000,
	1799082187582988032.000000, 2091998021343898112.000000,
	2432902008176640000.000000, 2829703400024258048.000000,
	3291622633316016128.000000, 3829409924568975872.000000,
	4455600509352979968.000000, 5184812699901632512.000000,
	6034095982728211456.000000, 7023337601767696384.000000,
	8175737505298668544.000000, 9518363211896655872.000000,
	11082798113786888192.000000, 12905899034260819968.000000,
	15030681546776809472.000000, 17507354714428235776.000000,
	20394530598642552832.000000, 23760638207976443904.000000,
	27685576620393250816.000000, 32262647942902747136.000000,
	37600817720484667392.000000, 43827358547154558976.000000,
	51090942171709440000.000000, 59565256570511179776.000000,
	69453237562967932928.000000, 80992019904633847808.000000,
	94458730798283309056.000000, 110177269872910680064.000000,
	128526244432109895680.000000, 149948257797741117440.000000,
	174960782613391736832.000000, 204168890895181742080.000000,
	238280159446417539072.000000, 278122124188320464896.000000,
	324662721410379415552.000000, 379034229567372132352.000000,
	442561313990543343616.000000, 516793881023488458752.000000,
	603545570324572012544.000000, 704938857552426565632.000000,
	823457908078615724032.000000, 962010520110036418560.000000,
	1124000727777607680000.000000, 1313413907379771146240.000000,
	1534916550141587750912.000000, 1793973240887666540544.000000,
	2096983823721896083456.000000, 2451444254672257286144.000000,
	2866135250836062732288.000000, 3351343561779493470208.000000,
	3919121530540000804864.000000, 4583591600596829863936.000000,
	5361303587544450990080.000000, 6271653900446604460032.000000,
	7337377503874582052864.000000, 8585125299700939882496.000000,
	10046141827585406926848.000000,
	11757060793284503273472.000000,
	13760839003400220704768.000000,
	16107852895072964050944.000000,
	18857186095000300027904.000000,
	22078141436525409206272.000000,
	25852016738885062098944.000000,
	30274190565103663841280.000000,
	35456572308270815903744.000000,
	41530480526549210628096.000000,
	48650024710347719442432.000000,
	56996078921129387884544.000000,
	66780951344480463618048.000000,
	78253872167551091343360.000000,
	91707443814635933794304.000000,
	107485223033995417092096.000000,
	125990634307294886625280.000000,
	147697449355517741760512.000000,
	173162109091438647050240.000000,
	203038213337927643037696.000000,
	238093561313773515440128.000000,
	279230193840505137135616.000000,
	327507968280925824876544.000000,
	384172291547486782226432.000000,
	450686747670504416477184.000000,
	528771487404781847183360.000000,
	620448401733239141564416.000000);

    # Find index into array
    my($alphaidx) = sprintf('%.0f', 20*$alpha) - 1;

    # Return Gamma value
    return $gammas[$alphaidx];
}


# Output morph length distribution

sub outputmorphlengthdistribution {
    my($morph, $info, $i);
    my($maxmorphlen) = 0;
    my(@nmorphtypesoflen) = ();

    foreach $i (1 .. $maxwordlen) {
	$nmorphtypesoflen[$i] = 0;
    }

    while (($morph, $info) = each %morphinfo) {
	my($wcount, $mcount, $msplit) = split(' ', $info);
	unless ($msplit) {	# It's a real morph
	    my($morphlen) = length($morph);
	    $nmorphtypesoflen[$morphlen]++;
	    $maxmorphlen = $morphlen if ($morphlen > $maxmorphlen);
	}
    }

    print "# Morph length occurrences in lexicon:\n";
    foreach $i (1 .. $maxmorphlen) {
	print "# $nmorphtypesoflen[$i] morphs of length $i.\n";
    }
}

# Load existing model from a file

sub loadmodel {
    my($count, $word, @morphs, $morph);  # Local variables

    %morphlogprob = ();	  # Global variable
    $nmorphtokens = 0;	  # -"-
    $nmorphtypes = 0;     # -"-
    $lognmorphtokens = 0; # -"-

    open(FILE, $modelfile) ||
	die "Error: Unable to open file '$modelfile' for reading.\n";

    while ($line = <FILE>) {
	chomp $line;

	next if ($line =~ /^\#/); # Comment

	if ($line =~ /^[ \t]*([0-9]+)[ \t](.+)$/) { # Segmented word preceded
						    # by a word count
	    $count = $1;
	    $word = $2;
	    @morphs = split(/ \+ /, $word);

	    foreach $morph (@morphs) {
		# Count the number of occurrences of every morph type
		# The variable name for $morphlogprob is misleading at
		# this stage. It actually contains morph counts:
		$morphlogprob{$morph} += $count;
		$nmorphtokens += $count;
	    }
	}
	else {	# Illegal format of line
	    die "Error ($me): Strange line in file '$modelfile': $line\n";
	}
    }

    close FILE;

    # Precompute morph logprobs, i.e., convert counts to
    # negative logprobs

    $lognmorphtokens = log($nmorphtokens);
    while (($morph, $count) = each %morphlogprob) {
	$morphlogprob{$morph} = $lognmorphtokens - log($count);
	$nmorphtypes++;
    }

    if ($trace & 2) {
	print "# Loaded model '$modelfile':\n";
	print "#   Number of morph tokens: $nmorphtokens\n";
	print "#   Number of morph types: $nmorphtypes\n";

    }
}

# Segment word using Viterbi search

sub viterbisegmentword {
    my($word, @crap) = @_;

    my($T) = length($word);
    my($badlikelihood) = ($T+1)*$lognmorphtokens;
    my($pseudoinfinitecost) = ($T+1)*$badlikelihood;
    my($t, $l, $morph, $logp);
    my(@delta, @psi, $bestdelta, $bestl, $currdelta);

    # Viterbi segmentation
    $delta[0] = 0;
    $psi[0] = 0;
    foreach $t (1 .. $T) {
	$bestdelta = $pseudoinfinitecost;
	$bestl = 0;
      L_LOOP:
	foreach $l (1 .. $t) {
	    $morph = substr($word, $t - $l, $l);
	    if (defined($morphlogprob{$morph})) {
		$logp = $morphlogprob{$morph};
	    }
	    elsif ($l == 1) {
		# The morph was not defined but it was only one letter long.
		# Accept it with a bad likelihood.
		$logp = $badlikelihood;
	    }
	    else {
		# The morph was not defined: Don't accept!
		next L_LOOP;
	    }
	    $currdelta = $delta[$t - $l] + $logp;
	    if ($currdelta < $bestdelta) {
		$bestdelta = $currdelta;
		$bestl = $l;
	    }
	}
	$delta[$t] = $bestdelta;
	$psi[$t] = $bestl;
    }

    # Trace back
    my(@morphseq) = ();
    $t = $T;
    while ($psi[$t]) {
	unshift @morphseq, substr($word, $t - $psi[$t], $psi[$t]);
	$t -= $psi[$t];
    }
    return @morphseq;
}

# Usage

sub usage {

die <<HERE
Usage:
$me [-finish int] [-rand int] [-savememory [int]]
[-gammalendistr [float1 [float2]]] [-zipffreqdistr [float]]
[-load filename] [-trace int] -data wordlist

Arguments:

-data wordlist: a text file (the corpus) consisting of one word per
line. The word may be preceded by a word count (separated by
whitespace), otherwise a count of one is assumed. If the same word
occurs many times, the counts are accumulated.

-finish float: convergence threshold. From one pass over all input words
to the next, if the overall coding length in bits (i.e. logprob) of the
lexicon together with the corpus improves less than this value times the
number of word types (distinct word forms) in the data, the program
stops. (If this value is small the program runs for a longer time and the
result is in principle more accurate. However, the changes in word
splittings during the last training epochs are usually very small.)
The value must be within the range: 0 < float < 1.
Default value: 0.005

-rand int: random seed that affects the sorting of words when
processing them.
Default value: 0

-savememory [int]: Save memory. This means that all words are not
guaranteed to be processed the same number of times, but memory
consumption decreases. The integer is a value that affects the
randomness of the order in which words are processed. High values
increase randomness, but may slow down the processing. If this option is
omitted, the saving memory feature is not used.
Default value: 8 (when the option is active)

-gammalendistr [float1 [float2]]: Float1 is the prior for the most
common morph length in the lexicon, such that 0 < float1 <= 24*float2.
Float2 is the beta value of the Gamma pdf, such that beta > 0. The
beta value affects the wideness of the morph length distribution. The
higher beta, the wider and less discriminative the distribution.
If this option is omitted, morphs in the lexicon are terminated with
an end-of-morph character, which corresponds to an exponential pdf for
morph lengths.
Default values: float1 = 7.0, float2 = 1.0 (when the option is active)

-zipffreqdistr [float]: Prior for the proportion of morphs in the lexicon
that occur only once in the data (hapax legomena): 0 < value < 1.
If this option is omitted a (non-informative) morph frequency
distribution based on enumerative coding is used instead.
Default value: 0.5 (when the option is active)

-load filename: An existing model for word splitting is loaded from a
file (which is the output of an earlier run of this program) and the
words in the corpus defined using the option '-data wordlist' are
segmented according to the loaded model. That is, no learning of a new
model takes place. The existing model is simply used for segmenting a
list of words. The segmentation takes place using Viterbi search. No
new morphs are ever created (except one-letter morphs, if there is no
other way of segmenting a particular input word).

-trace int: output control
Values:
trace & 1   => Flush output
trace & 2   => Output progress feedback (how many words processed etc.)
trace & 4   => Output each word when processed and its segmentation
trace & 8   => Trace recursive splitting of morphs
trace & 16  => Output resulting morph length distribution
Default value: 0

HERE
}
