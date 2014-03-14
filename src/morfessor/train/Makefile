#
# Makefile for learning a segmentation model and segmenting the words in a
# dataset using the Morfessor Categories-MAP algorithm.
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
#
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

GZIPPEDINPUTDATA = wsj.words.clean.gz

# You also need to "guess" a good value for the perplexity threshold
# PPLTHRESH (called b in the publications). The more data you have the
# higher b. Also, the higher b, the less words are split, and
# typically the higher precision (but lower recall). Conversely, the
# lower b value, the more words are split and typically recall is
# higher at the expense of lower precision.  It is difficult to tell
# you what b should be. In our data sets ranging from thousands to
# millions of words, b has been in the range of 10 .. 400.

PPLTHRESH = 200

# If you want to try different random seeds (used to produce the initial
# baseline segmentation), modify this:

RANDSEED = 0

# Location of Morfessor Perl scripts

BINDIR = ../bin

# That's all! Run "make" or "make all". The result is written to the file
# segmentation.final.gz. Once done, you can remove all intermediate
# (superfluous) files by typing "make clean" or remove all produced files
# by typing "make realclean".
#
# 3. PROGRAM CODE STARTS HERE
#

all: segmentation.final.gz

ZCAT = zcat

ITERS = i ii iii iiii iiiii iiiiii iiiiiii iiiiiiii iiiiiiiii iiiiiiiiii

# First, produce an initial segmentation using the Morfessor Baseline
# algorithm. Note: The Baseline algorithm does not depend on the value
# of PPLTHRESH, so if you want to try different PPLTHRESH values, you
# can produce the file baselineseg.final.gz only once, and then run
# the rest using different PPLTHRESH values.

traindata.nowcounts.gz: $(GZIPPEDINPUTDATA)
	echo Threshold ${PPLTHRESH} 
        # Don't use word counts to train the initial baseline segmentation
        # using Morfessor Baseline
	$(ZCAT) $< | sed 's/^[0-9]*/1/' | sort -u | gzip > $@
TMPS += traindata.nowcounts.gz

baselineseg.i.gz: traindata.nowcounts.gz
        # Run Morfessor to train a segmentation model
	$(ZCAT) $< > traindata
	$(BINDIR)/morfessor1.0.pl -trace 3 $(PARAMS) -data traindata \
	> baselineseg.i
	rm -f traindata
	gzip baselineseg.i
TARGETS += baselineseg.i.gz
TMPS += traindata baselineseg.i

$(addsuffix .gz, $(addprefix baselineseg.i, $(ITERS))): \
baselineseg.i%.gz: baselineseg.%.gz
        # Resegment using the Viterbi algorithm
	$(ZCAT) traindata.nowcounts.gz > traindata
	$(ZCAT) baselineseg.$*.gz > baselineseg.$*
	$(BINDIR)/morfessor1.0.pl -trace 3 -data traindata \
	-load baselineseg.$* > baselineseg.i$*
	rm -f traindata baselineseg.$*
	gzip baselineseg.i$*
TMPS += $(addsuffix .gz, $(addprefix baselineseg.i, $(ITERS)))
TMPS += $(addprefix baselineseg.i, $(ITERS))

baselineseg.final.gz: baselineseg.iiiiii.gz
        # Re-insert the word counts into the final output file
	$(CATWORDCOUNTS) > wordcounts.tmp
	$(ZCAT) $< | sed 's/^[0-9]* //' | \
	$(BINDIR)/display_morph_counts.pl wordcounts.tmp | gzip > $@
	rm -f wordcounts.tmp
TARGETS += baselineseg.final.gz
TMPS += wordcounts.tmp

# When the Baseline segmentation is done, move over to Categories-MAP

ESTIMATEPROBPARAMS = -pplthresh $(PPLTHRESH)

SPLITPARAMS = -pplthresh $(PPLTHRESH)

JOINPARAMS = -pplthresh $(PPLTHRESH)

CATWORDCOUNTS = $(ZCAT) $(GZIPPEDINPUTDATA)

# MAXCHANGES1 approx. equals the number of word types in the data div. by 100
MAXCHANGES1 = $(shell $(CATWORDCOUNTS) | wc -l | sed 's/..$$//')

# MAXCHANGES1 approx. equals the number of word types in the data div. by 10
MAXCHANGES2 = $(shell $(CATWORDCOUNTS) | wc -l | sed 's/.$$//')

#
# Initial category tags for Baseline segmentation
#

baseline.probs.gz: baselineseg.final.gz
        # Estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> baseline.probs
	rm -f $@
	gzip baseline.probs
TMPS += baseline.probs.gz

baseline.i.tagged.gz: baseline.probs.gz
        # Tag the baseline segmentation
	$(ZCAT) $< > $<.tmp
	$(ZCAT) baselineseg.final.gz | $(BINDIR)/viterbitag.pl $<.tmp \
	> baseline.i.tagged
	rm -f $<.tmp $@
	gzip baseline.i.tagged
TMPS += baseline.i.tagged.gz

# Viterbi-EM for tagging of baseline segmentation

$(addsuffix .probs.gz, $(addprefix baseline., $(ITERS))):
baseline.%.probs.gz: baseline.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> baseline.$*.probs
	rm -f $@
	gzip baseline.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix baseline., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix baseline.i, $(ITERS))):
baseline.i%.tagged.gz: baseline.%.probs.gz
        # Re-tag the baseline segmentation
	$(ZCAT) $< > $<.tmp
	$(ZCAT) baselineseg.final.gz | $(BINDIR)/viterbitag.pl $<.tmp \
	> baseline.i$*.tagged
	rm -f $<.tmp $@
	gzip baseline.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix baseline.i, $(ITERS)))

alphabetprobs: baselineseg.i.gz
        # Collect logprobs for the letters in the alphabet (log2)
	$(ZCAT) $< | \
	grep "^# . \->" | sed 's/^# //' | sed 's/ \-> /	/' > $@
TMPS += alphabetprobs

#
# Split baseline even further using sub-structures. Make one pass over the
# entire material.
#

baseline.substructs.tagged.gz: alphabetprobs baseline.iiiii.probs.gz
        # Re-analyze morphs in order to find sub-structure
	$(ZCAT) baseline.iiiii.probs.gz > baseline.iiiii.probs.tmp
	$(ZCAT) baseline.iiiii.tagged.gz > baseline.iiiii.tagged.tmp
	$(BINDIR)/resplitmorphs.pl $(SPLITPARAMS) -maxchanges 100000000 \
	-probs baseline.iiiii.probs.tmp -alphabet alphabetprobs \
	-segmentation baseline.iiiii.tagged.tmp	> baseline.substructs.tagged
	rm -f baseline.iiiii.probs.tmp baseline.iiiii.tagged.tmp $@
	gzip baseline.substructs.tagged
TMPS += baseline.substructs.tagged.gz

baseline.resplit.tagged.gz: baseline.substructs.tagged.gz
        # Expand the sub-structures in order to get an even more
        # fine-grained segmentation
	$(ZCAT) $< > $<.tmp
	$(BINDIR)/expandmorphsegmentations.pl -full $<.tmp \
	> baseline.resplit.tagged
	rm -f $<.tmp $@
	gzip baseline.resplit.tagged
TMPS += baseline.resplit.tagged.gz

baseline.resplit.probs.gz: baseline.resplit.tagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> baseline.resplit.probs
	rm -f $@
	gzip baseline.resplit.probs
TMPS += baseline.resplit.probs.gz

baseline.resplit.retagged.gz: baseline.resplit.probs.gz
        # Re-estimate tagging
	$(ZCAT) $< > $<.tmp
	$(ZCAT) baseline.resplit.tagged.gz | sed 's/\/[^ ]*//g' | \
	$(BINDIR)/viterbitag.pl $<.tmp > baseline.resplit.retagged
	rm -f $<.tmp $@
	gzip baseline.resplit.retagged
TMPS += baseline.resplit.retagged.gz

baseline.resplit.reprobs.gz: baseline.resplit.retagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> baseline.resplit.reprobs
	rm -f $@
	gzip baseline.resplit.reprobs
TMPS += baseline.resplit.reprobs.gz

#
# Re-joining morphs using context-dependent model
#

# Join morphs bottom-up, a maximum of 10 000 changes per iteration

joined.i.tagged.gz: baseline.resplit.reprobs.gz
        # Start joining morphs according to complete cost function
	$(ZCAT) baseline.resplit.reprobs.gz > baseline.resplit.reprobs.tmp
	$(ZCAT) baseline.resplit.retagged.gz > baseline.resplit.retagged.tmp
	$(BINDIR)/joinmorphs.pl $(JOINPARAMS) -maxchanges $(MAXCHANGES1) \
	-probs baseline.resplit.reprobs.tmp -alphabet alphabetprobs \
	-segmentation baseline.resplit.retagged.tmp > joined.i.tagged
	rm -f baseline.resplit.reprobs.tmp baseline.resplit.retagged.tmp $@
	gzip joined.i.tagged
TMPS += joined.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix joined., $(ITERS))):
joined.%.probs.gz: joined.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> joined.$*.probs
	rm -f $@
	gzip joined.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix joined., $(ITERS)))

$(addsuffix .retagged.gz, $(addprefix joined., $(ITERS))):
joined.%.retagged.gz: joined.%.probs.gz
        # Re-estimate tagging
	$(ZCAT) $< > $<.tmp
	$(ZCAT) joined.$*.tagged.gz | grep -v "^1 \*" | sed 's/\/[^ ]*//g' | \
	$(BINDIR)/viterbitag.pl $<.tmp > joined.$*.retagged
	$(ZCAT) joined.$*.tagged.gz | grep "^1 \*" >> joined.$*.retagged
	rm -f $<.tmp $@
	gzip joined.$*.retagged
TMPS += $(addsuffix .retagged.gz, $(addprefix joined., $(ITERS)))

$(addsuffix .reprobs.gz, $(addprefix joined., $(ITERS))):
joined.%.reprobs.gz: joined.%.retagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> joined.$*.reprobs
	rm -f $@
	gzip joined.$*.reprobs
TMPS += $(addsuffix .reprobs.gz, $(addprefix joined., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix joined.i, $(ITERS))):
joined.i%.tagged.gz: joined.%.reprobs.gz
        # Join more morphs
	$(ZCAT) $< > $<.tmp
	$(ZCAT) joined.$*.retagged.gz > joined.$*.retagged.tmp
	$(BINDIR)/joinmorphs.pl $(JOINPARAMS) -maxchanges $(MAXCHANGES1) \
	-probs $<.tmp -alphabet alphabetprobs \
	-segmentation joined.$*.retagged.tmp > joined.i$*.tagged
	rm -f $<.tmp joined.$*.retagged.tmp $@
	gzip joined.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix joined.i, $(ITERS)))

#
# Reanalyze sub-structures
#

resplit.i.tagged.gz: joined.iiiiiiiiii.reprobs.gz
        # Reanalyze morphs according to complete cost function
	$(ZCAT) joined.iiiiiiiiii.reprobs.gz > joined.iiiiiiiiii.reprobs.tmp
	$(ZCAT) joined.iiiiiiiiii.retagged.gz > joined.iiiiiiiiii.retagged.tmp
	$(BINDIR)/resplitmorphs.pl $(SPLITPARAMS) \
	-maxchanges $(MAXCHANGES1) \
	-probs joined.iiiiiiiiii.reprobs.tmp -alphabet alphabetprobs \
	-segmentation joined.iiiiiiiiii.retagged.tmp > resplit.i.tagged
	rm -f joined.iiiiiiiiii.reprobs.tmp joined.iiiiiiiiii.retagged.tmp $@
	gzip resplit.i.tagged
TMPS += resplit.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix resplit., $(ITERS))):
resplit.%.probs.gz: resplit.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> resplit.$*.probs
	rm -f $@
	gzip resplit.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix resplit., $(ITERS)))

$(addsuffix .retagged.gz, $(addprefix resplit., $(ITERS))):
resplit.%.retagged.gz: resplit.%.probs.gz
        # Re-estimate tagging
	$(ZCAT) $< > $<.tmp
	$(ZCAT) resplit.$*.tagged.gz | grep -v "^1 \*" | sed 's/\/[^ ]*//g' | \
	$(BINDIR)/viterbitag.pl $<.tmp > resplit.$*.retagged
	$(ZCAT) resplit.$*.tagged.gz | grep "^1 \*" >> resplit.$*.retagged
	rm -f $<.tmp $@
	gzip resplit.$*.retagged
TMPS += $(addsuffix .retagged.gz, $(addprefix resplit., $(ITERS)))

$(addsuffix .reprobs.gz, $(addprefix resplit., $(ITERS))):
resplit.%.reprobs.gz: resplit.%.retagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> resplit.$*.reprobs
	rm -f $@
	gzip resplit.$*.reprobs
TMPS += $(addsuffix .reprobs.gz, $(addprefix resplit., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix resplit.i, $(ITERS))):
resplit.i%.tagged.gz: resplit.%.reprobs.gz
        # Reanalyze further
	$(ZCAT) $< > $<.tmp
	$(ZCAT) resplit.$*.retagged.gz > resplit.$*.retagged.tmp
	$(BINDIR)/resplitmorphs.pl $(SPLITPARAMS) \
	-maxchanges $(MAXCHANGES1) \
	-probs $<.tmp -alphabet alphabetprobs \
	-segmentation resplit.$*.retagged.tmp > resplit.i$*.tagged
	rm -f $<.tmp resplit.$*.retagged.tmp $@
	gzip resplit.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix resplit.i, $(ITERS)))

#
# Re-analyze the surface segmentations
#

viterbitagsplit.i.tagged.gz: resplit.iiiiiii.reprobs.gz
        # Re-segment the whole material
	$(ZCAT) resplit.iiiiiii.reprobs.gz > resplit.iiiiiii.tmp
	$(CATWORDCOUNTS) | $(BINDIR)/viterbitagsplit.pl \
	-probs resplit.iiiiiii.tmp > viterbitagsplit.i.tagged
	$(ZCAT) resplit.iiiiiii.retagged.gz | grep "^1 \*" \
	>> viterbitagsplit.i.tagged
	rm -f resplit.iiiiiii.tmp $@
	gzip viterbitagsplit.i.tagged
TMPS += viterbitagsplit.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix viterbitagsplit., $(ITERS))):
viterbitagsplit.%.probs.gz: viterbitagsplit.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> viterbitagsplit.$*.probs
	rm -f $@
	gzip viterbitagsplit.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix viterbitagsplit., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix viterbitagsplit.i, $(ITERS))):
viterbitagsplit.i%.tagged.gz: viterbitagsplit.%.probs.gz
        # Reanalyze further
	$(ZCAT) $< > $<.tmp
	$(CATWORDCOUNTS) | $(BINDIR)/viterbitagsplit.pl -probs $<.tmp \
	> viterbitagsplit.i$*.tagged
	$(ZCAT) viterbitagsplit.$*.tagged.gz | grep "^1 \*" \
	>> viterbitagsplit.i$*.tagged
	rm -f $<.tmp $@
	gzip viterbitagsplit.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix viterbitagsplit.i, $(ITERS)))

# Join morphs bottom-up, a maximum of 100 000 changes per iteration

joined2.i.tagged.gz: viterbitagsplit.iii.probs.gz
        # Start joining morphs according to complete cost function
	$(ZCAT) viterbitagsplit.iii.probs.gz > viterbitagsplit.iii.probs.tmp
	$(ZCAT) viterbitagsplit.iii.tagged.gz > viterbitagsplit.iii.tagged.tmp
	$(BINDIR)/joinmorphs.pl $(JOINPARAMS) -maxchanges $(MAXCHANGES2) \
	-probs viterbitagsplit.iii.probs.tmp -alphabet alphabetprobs \
	-segmentation viterbitagsplit.iii.tagged.tmp > joined2.i.tagged
	rm -f viterbitagsplit.iii.probs.tmp viterbitagsplit.iii.tagged.tmp $@
	gzip joined2.i.tagged
TMPS += joined2.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix joined2., $(ITERS))):
joined2.%.probs.gz: joined2.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> joined2.$*.probs
	rm -f $@
	gzip joined2.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix joined2., $(ITERS)))

$(addsuffix .retagged.gz, $(addprefix joined2., $(ITERS))):
joined2.%.retagged.gz: joined2.%.probs.gz
        # Re-estimate tagging
	$(ZCAT) $< > $<.tmp
	$(ZCAT) joined2.$*.tagged.gz | grep -v "^1 \*" | sed 's/\/[^ ]*//g' | \
	$(BINDIR)/viterbitag.pl $<.tmp > joined2.$*.retagged
	$(ZCAT) joined2.$*.tagged.gz | grep "^1 \*" >> joined2.$*.retagged
	rm -f $<.tmp $@
	gzip joined2.$*.retagged
TMPS += $(addsuffix .retagged.gz, $(addprefix joined2., $(ITERS)))

$(addsuffix .reprobs.gz, $(addprefix joined2., $(ITERS))):
joined2.%.reprobs.gz: joined2.%.retagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> joined2.$*.reprobs
	rm -f $@
	gzip joined2.$*.reprobs
TMPS += $(addsuffix .reprobs.gz, $(addprefix joined2., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix joined2.i, $(ITERS))):
joined2.i%.tagged.gz: joined2.%.reprobs.gz
        # Join more morphs
	$(ZCAT) $< > $<.tmp
	$(ZCAT) joined2.$*.retagged.gz > joined2.$*.retagged.tmp
	$(BINDIR)/joinmorphs.pl $(JOINPARAMS) -maxchanges $(MAXCHANGES2) \
	-probs $<.tmp -alphabet alphabetprobs \
	-segmentation joined2.$*.retagged.tmp > joined2.i$*.tagged
	rm -f $<.tmp joined2.$*.retagged.tmp $@
	gzip joined2.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix joined2.i, $(ITERS)))

#
# Reanalyze sub-structures, second time
#

resplit2.i.tagged.gz: joined2.iiiiiiii.reprobs.gz
        # Reanalyze morphs according to complete cost function
	$(ZCAT) joined2.iiiiiiii.reprobs.gz > joined2.iiiiiiii.reprobs.tmp
	$(ZCAT) joined2.iiiiiiii.retagged.gz > joined2.iiiiiiii.retagged.tmp
	$(BINDIR)/resplitmorphs.pl $(SPLITPARAMS) \
	-maxchanges $(MAXCHANGES2) \
	-probs joined2.iiiiiiii.reprobs.tmp -alphabet alphabetprobs \
	-segmentation joined2.iiiiiiii.retagged.tmp > resplit2.i.tagged
	rm -f joined2.iiiiiiii.reprobs.tmp joined2.iiiiiiii.retagged.tmp $@
	gzip resplit2.i.tagged
TMPS += resplit2.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix resplit2., $(ITERS))):
resplit2.%.probs.gz: resplit2.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> resplit2.$*.probs
	rm -f $@
	gzip resplit2.$*.probs
TMPS += $(addsuffix .probs.gz, $(addprefix resplit2., $(ITERS)))

$(addsuffix .retagged.gz, $(addprefix resplit2., $(ITERS))):
resplit2.%.retagged.gz: resplit2.%.probs.gz
        # Re-estimate tagging
	$(ZCAT) $< > $<.tmp
	$(ZCAT) resplit2.$*.tagged.gz | grep -v "^1 \*" | \
	sed 's/\/[^ ]*//g' | \
	$(BINDIR)/viterbitag.pl $<.tmp > resplit2.$*.retagged
	$(ZCAT) resplit2.$*.tagged.gz | grep "^1 \*" >> resplit2.$*.retagged
	rm -f $<.tmp $@
	gzip resplit2.$*.retagged
TMPS += $(addsuffix .retagged.gz, $(addprefix resplit2., $(ITERS)))

$(addsuffix .reprobs.gz, $(addprefix resplit2., $(ITERS))):
resplit2.%.reprobs.gz: resplit2.%.retagged.gz
        # Estimate probs
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> resplit2.$*.reprobs
	rm -f $@
	gzip resplit2.$*.reprobs
TMPS += $(addsuffix .reprobs.gz, $(addprefix resplit2., $(ITERS)))

$(addsuffix .tagged.gz, $(addprefix resplit2.i, $(ITERS))):
resplit2.i%.tagged.gz: resplit2.%.reprobs.gz
        # Reanalyze further
	$(ZCAT) $< > $<.tmp
	$(ZCAT) resplit2.$*.retagged.gz > resplit2.$*.retagged.tmp
	$(BINDIR)/resplitmorphs.pl $(SPLITPARAMS) \
	-maxchanges $(MAXCHANGES2) \
	-probs $<.tmp -alphabet alphabetprobs \
	-segmentation resplit2.$*.retagged.tmp > resplit2.i$*.tagged
	rm -f $<.tmp resplit2.$*.retagged.tmp $@
	gzip resplit2.i$*.tagged
TMPS += $(addsuffix .tagged.gz, $(addprefix resplit2.i, $(ITERS)))

#
# Re-analyze the surface segmentations
#

viterbitagsplit2.i.tagged.gz: resplit2.iiiiii.reprobs.gz
        # Re-segment the whole material
	$(ZCAT) resplit2.iiiiii.reprobs.gz > resplit2.iiiiii.tmp
	$(CATWORDCOUNTS) | $(BINDIR)/viterbitagsplit.pl \
	-probs resplit2.iiiiii.tmp > viterbitagsplit2.i.tagged
	$(ZCAT) resplit2.iiiiii.retagged.gz | grep "^1 \*" \
	>> viterbitagsplit2.i.tagged
	rm -f resplit2.iiiiii.tmp $@
	gzip viterbitagsplit2.i.tagged
TMPS += viterbitagsplit2.i.tagged.gz

$(addsuffix .probs.gz, $(addprefix viterbitagsplit2., $(ITERS))):
viterbitagsplit2.%.probs.gz: viterbitagsplit2.%.tagged.gz
        # Re-estimate category emission probs etc.
	$(ZCAT) $< | $(BINDIR)/estimateprobs.pl $(ESTIMATEPROBPARAMS) \
	> viterbitagsplit2.$*.probs
	rm -f $@
	gzip viterbitagsplit2.$*.probs
TMPS += viterbitagsplit2.i.probs.gz
TARGETS += viterbitagsplit2.ii.probs.gz

$(addsuffix .tagged.gz, $(addprefix viterbitagsplit2.i, $(ITERS))):
viterbitagsplit2.i%.tagged.gz: viterbitagsplit2.%.probs.gz
        # Reanalyze further
	$(ZCAT) $< > $<.tmp
	$(CATWORDCOUNTS) | $(BINDIR)/viterbitagsplit.pl -probs $<.tmp \
	> viterbitagsplit2.i$*.tagged
	$(ZCAT) viterbitagsplit2.$*.tagged.gz | grep "^1 \*" \
	>> viterbitagsplit2.i$*.tagged
	rm -f $<.tmp $@
	gzip viterbitagsplit2.i$*.tagged
TARGETS += viterbitagsplit2.ii.tagged.gz viterbitagsplit2.iii.tagged.gz

analysis.withnonmorphemes.gz: viterbitagsplit2.iii.tagged.gz
        # Expand segmentations
	$(ZCAT) $< > $<.tmp
	$(BINDIR)/expandmorphsegmentations.pl -full $<.tmp | \
	perl -pe 'while ($$_ =~ s,([^/]+)/ZZZ \+ ([^/]+)/ZZZ,$$1$$2/ZZZ,) {}' \
	> analysis.withnonmorphemes
	rm -f $<.tmp $@
	gzip analysis.withnonmorphemes
TARGETS += analysis.withnonmorphemes.gz

segmentation.final.gz: analysis.withnonmorphemes.gz
        # Convert non-morphemes to stems
	$(ZCAT) $< | sed 's/\/ZZZ/\/STM/g' | gzip > $@
TARGETS += segmentation.final.gz

.PHONY: clean
clean:
        # Remove all temporary files
	rm -f $(TMPS)

.PHONY: realclean
realclean:
        # Remove all files created by this Makefile.
	rm -f $(TARGETS) $(TMPS)

