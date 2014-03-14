#
# Makefile for segmenting the words in a dataset according to an *existing
# model* trained using Morfessor Categories-MAP.
# Mathias Creutz, 18 Oct 2006.
#
#
# 1. CONDITIONS OF USE
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
#
# The users of Morfessor Categories-MAP are requested to refer to one of
# the following publications in their scientific publications:
#
# * Mathias Creutz and Krista Lagus (2005). Inducing the Morphological
# Lexicon of a Natural Language from Unannotated Text. In Proceedings
# of the International and Interdisciplinary Conference on Adaptive
# Knowledge Representation and Reasoning (AKRR'05), pages 106-113,
# Espoo, June. http://www.cis.hut.fi/mcreutz/papers/Creutz05akrr.pdf
#
# * Mathias Creutz (2006). Induction of the Morphology of Natural
# Language: Unsupervised Morpheme Segmentation with Application to
# Automatic Speech Recognition. Doctoral thesis, Dissertations in
# Computer and Information Science, Report D13, Helsinki Univeristy of
# Technology, Espoo, Finland. http://lib.tkk.fi/Diss/2006/isbn9512282119/
#
# * Mathias Creutz and Krista Lagus. Unsupervised Models for Morpheme
# Segmentation and Morphology Learning. ACM Transactions on Speech and
# Language Processing (in press).
#
#
# 2. USER'S INSTRUCTIONS
#
# You need GNU Make and a Perl interpreter under Linux in order to run
# Morfessor Categories MAP.
# The input data is a gzipped file containing a list of words, one word
# on each line preceded by the frequency of that word in the data (separated
# from the word by a space character), e.g., 
#
# ...
# 1 aakkosellisiin
# 2 aakkosellista
# 2 aakkosen
# 50 aakkoset
# 23 aakkosia
# 1 aakkosiaan
# 3 aakkosiin
# ...
#
# Line breaks consist of the newline character \n. Remove all carriage
# return characters \r (which may occur in your file if you have processed
# it using Windows). No word may contain slash (/), asterisk (*), or number
# sign (#) characters. UTF-8 encoding is not supported. All characters are
# (8-bit) bytes.
#
# Write the location of the gzipped input data file here:

GZIPPEDINPUTDATA = mydata2.gz

# Indicate the location of the directory, where the segmentation model was
# trained. (Three files from that directory will be needed:
# viterbitagsplit2.ii.tagged.gz, viterbitagsplit2.ii.probs.gz, and
# segmentation.final.gz.)
#

TRAINDIR = ../train

# Indicate the location of the Morfessor Perl scripts

BINDIR = ../bin

# That's all! Run "make" or "make all". The result is written to the file
# segmentation.final.gz. Once done, you can remove all intermediate
# (superfluous) files by typing "make clean" or remove all produced files
# by typing "make realclean".
#
# 3. PROGRAM CODE STARTS HERE
#

ZCAT = zcat

all: segmentation.final.gz

segmentation.existing.gz: $(TRAINDIR)/segmentation.final.gz
        # Pick existing segmentations for the words that were present
        # in the training data. We don't need to generate new segmentations
        # for these words. We will, however, modify the format of the file, so
        # that each line will look like this:
        # <word><TAB><segmentation_of_word>
	$(ZCAT) $< | grep "^[0-9]" | sed 's/^[0-9]* //' | \
	perl -ne 'chomp; $$w = $$_; $$w =~ s,/[^ ]+,,g; $$w =~ tr/+ //d; \
        print "$$w\t$$_\n";' | sort | gzip > $@
TMPS += segmentation.existing.gz

wordcounts.tobesegmented.gz: $(GZIPPEDINPUTDATA)
        # Make a list of the words in the test set
	$(ZCAT) $< | tr ' ' '\t' | sort -k 2 | gzip > $@
TMPS += wordcounts.tobesegmented.gz

testset.segmentation.existing.gz: \
        wordcounts.tobesegmented.gz segmentation.existing.gz
        # Collect segmentations for the words in the test set by look-up
	$(ZCAT) wordcounts.tobesegmented.gz > wordcounts.tobesegmented
	$(ZCAT) segmentation.existing.gz > segmentation.existing
	join -1 2 -2 1 -t '	' -o '1.1 1.2 2.2' -a 1 \
	wordcounts.tobesegmented segmentation.existing | gzip > $@
	rm -f wordcounts.tobesegmented segmentation.existing
TMPS += testset.segmentation.existing.gz
TMPS += wordcounts.tobesegmented segmentation.existing

testset.segmentation.lacking.gz: testset.segmentation.existing.gz
        # Make a list of the words that lack a segmentation
	$(ZCAT) $< | grep "	$$" | tr '\t' ' ' | sed 's/ $$//' | gzip > $@
TMPS += testset.segmentation.lacking.gz

testset.segmented.gz: testset.segmentation.lacking.gz
        # Segment words with no supplied segmentation
	$(ZCAT) $(TRAINDIR)/viterbitagsplit2.ii.probs.gz > probs.tmp
	$(ZCAT) $< | $(BINDIR)/viterbitagsplit_testset.pl -probs probs.tmp | \
	sed 's/^\([0-9]*\) \([^\/]*\)$$/\1 \2\/ZZZ/' > segmentedwords.tmp
	$(ZCAT) $(TRAINDIR)/viterbitagsplit2.ii.tagged.gz | grep "^1 \*" \
	>> segmentedwords.tmp
	$(BINDIR)/expandmorphsegmentations.pl segmentedwords.tmp | \
        perl -pe 'while ($$_ =~ s,([^/]+)/ZZZ \+ ([^/]+)/ZZZ,$$1$$2/ZZZ,) {}' \
	| sed 's/ZZZ/STM/g' | grep "^[0-9]" | sed 's/^[0-9]* //' | \
	perl -ne 'chomp; $$w = $$_; $$w =~ s,/[^ ]+,,g; $$w =~ s/ \+ //g; \
        print "$$w\t$$_\n";' | gzip > $@
	rm -f probs.tmp segmentedwords.tmp
TMPS += testset.segmented.gz probs.tmp segmentedwords.tmp

segmentation.final.gz: testset.segmentation.existing.gz testset.segmented.gz
        # Combine all segmentations into one file
	$(ZCAT) testset.segmentation.existing.gz \
	> testset.segmentation.existing
	$(ZCAT) testset.segmented.gz > testset.segmented
	join -1 2 -2 1 -t '	' -o '1.1 1.3 2.2' -a 1 \
	testset.segmentation.existing testset.segmented | tr '\t' ' ' | \
	sed 's/  */ /g' | gzip > $@
	rm -f testset.segmentation.existing testset.segmented
TARGETS += segmentation.final.gz
TMPS += testset.segmentation.existing testset.segmented

.PHONY: clean
clean:
        # Remove all temporary files
	rm -f $(TMPS)

.PHONY: realclean
realclean:
        # Remove all files created by this Makefile.
	rm -f $(TARGETS) $(TMPS)

