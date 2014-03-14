SEED=1 # Random seed
SRILM_PATH=/opt/srilm/bin/i686-m64 # Change to your SRILM Path
export PATH := ../bin:.:${SRILM_PATH}:${PATH} # Binaries in the bin directory

.PRECIOUS: %.pairs.gz %.unk-pairs.gz %.sub.gz %.words.gz %.knn128.gz %.feat.gz %.knn.gz %.knn.sc-f.gz %.knn.sc.gz

bin:
	cd ../bin; make all
#___________________________________________________________________________________________
### SRILM options:
LM_NGRAM=4 # n-gram order
LM_VOCAB=2 # words seen less than this in GETTRAIN will be replaced with <unk>
LM_MTYPE=i686-m64 # architecture for compiling srilm
LM_DISCOUNT=-kndiscount

%.words.gz: ../data/%.tok.gz
	zcat $< | awk '{for(i=1;i<=NF;i++)print $$i}' | gzip > $@

%.vocab.gz: ../data/%.tok.gz
	zcat $< | ngram-count -write-order 1 -text - -write - | \
	perl -lane 'print $$F[0] if $$F[1] >= ${LM_VOCAB}' | gzip > $@
%.unk-vocab.gz: ../data/%.tok.gz
	zcat $< | ngram-count -write-order 1 -text - -write - | \
	perl -lane 'print $$F[0] if $$F[1] < ${LM_VOCAB}' | gzip > $@


%.lm.gz: %.vocab.gz ../data/%.tok.gz
	zcat ../data/$*.tok.gz | ngram-count -order ${LM_NGRAM} ${LM_DISCOUNT} -interpolate -unk -vocab $< -text - -lm $@

%.ppl.gz: %.lm.gz %.tok.gz
	zcat $*.tok.gz | \
	ngram -order ${LM_NGRAM} -unk -lm $< -ppl - | gzip > $@

%.unk: %.vocab.gz %.tok.gz # Calculates unknown word ratio
	unknown.pl $< $*.tok.gz > $@
#___________________________________________________________________________________________

### FASTSUBS options:
FS_NSUB=100 # go until you have this many substitutes
FS_PSUB=1.0 # or this much cumulative probability
FS_OPTIONS=-n ${FS_NSUB} -p ${FS_PSUB}

export OMP_NUM_THREADS=24
LMFILE=
#%.sub.gz: %.tok.gz %.lm.gz  %.ppl.gz %.unk 
%.sub.gz: ../data/%.tok.gz $(LMFILE).lm.gz
	zcat $< | fastsubs-omp ${FS_OPTIONS} $(LMFILE).lm.gz | gzip > $@

### WORDSUB options:
WORDSUB=100 # Number of random substitutes per word
WS_OPTIONS=-n ${WORDSUB} -s ${SEED}

%.pairs.gz: %.sub.gz
	perl -le 'print "$<" for 1..${WORDSUB}' | xargs zcat | grep -v '^</s>' | wordsub -s ${SEED} | gzip > $@
%.unk-pairs.gz: %.pairs.gz %.unk-vocab.gz
	unkPairs.py $< $*.unk-vocab.gz | gzip > $@

#___________________________________________________________________________________________
### MORFESSOR OPTIONS
MORFESSOR=../src/morfessor
PPLTHRESH=10
MOR_TOP_WORD=2000
MOR_LEAST_WORD=0
DIS_FEAT_OPT=300

%.mor.gz: %.words.gz
	zcat $< | sort | uniq -c | sort -rn | perl -lane 'print $$F[1] if $$F[0] >= ${MOR_LEAST_WORD} && $$F[0] < ${MOR_TOP_WORD}' | \
	run-morfessor.pl -m ${MORFESSOR} -p ${PPLTHRESH} | gzip > $@ 

%.seg.gz: %.mor.gz %.words.gz
	zcat $< | getSuf.py $*.words.gz | gzip > $@

%.feat.gz: %.seg.gz ../data/%.tok.gz
	feature-table.pl ${DIS_FEAT_OPT} -c $< -w ../data/$*.tok.gz | gzip > $@

FEATUREFLAG=
%.pairs+f.gz: %.pairs.gz $(FEATFILE).feat.gz
	zcat $< | add-features-3.pl -f $(FEATFILE).feat.gz | gzip > $@
%.unk-pairs+f.gz: %.unk-pairs.gz $(FEATFILE).feat.gz
	zcat $< | add-features-3.pl -f $(FEATFILE).feat.gz | gzip > $@

#___________________________________________________________________________________________
### SCODE options:
DIM=25
SC_OPTIONS=-v -r 1 -t 0.001 -d $(DIM) -z 0.166 -p 50 -u 0.2 -s ${SEED}

%.scode-$(DIM)$(FEATUREFLAG).gz : %.pairs$(FEATUREFLAG).gz
	zcat $< | scode ${SC_OPTIONS} | gzip > $@

%.unk-scode-$(DIM)$(FEATUREFLAG).gz: %.unk-pairs$(FEATUREFLAG).gz
	zcat $< | scode ${SC_OPTIONS} | gzip > $@
#___________________________________________________________________________________________
### Word-Type Vectors:

%.type-$(DIM)$(FEATUREFLAG).gz: %.scode-$(DIM)$(FEATUREFLAG).gz
	zcat $< | perl -ne 'print if s/^0://' | cut -f1,3-`echo $(DIM) | awk '{print $$1+2}'`| gzip > $@

%.unk-type-$(DIM)$(FEATUREFLAG).gz: %.unk-scode-$(DIM)$(FEATUREFLAG).gz
	zcat $< | perl -ne 'print if s/^0://' | cut -f1,3-`echo $(DIM) | awk '{print $$1+2}'`| gzip > $@

#___________________________________________________________________________________________
### Word-Token Vectors Based On Substitute Pairs & Distribution

X1=
X2=
LENGTH=`zcat ../data/$*.tok.gz | wc -w`
%.XmixX$(FEATUREFLAG).gz: %.unk-pairs$(FEATUREFLAG).gz $(X1) $(X2)
	XmixX.py $< $(X1) $(X2) ${LENGTH} | gzip > $@
%.XplusX$(FEATUREFLAG).gz: %.unk-pairs$(FEATUREFLAG).gz %.unk-scode-$(DIM)$(FEATUREFLAG).gz
	Xplus.py $< $*.unk-scode-$(DIM)$(FEATUREFLAG).gz ${LENGTH} x | gzip > $@
%.XplusY$(FEATUREFLAG).gz: %.unk-pairs$(FEATUREFLAG).gz %.unk-scode-$(DIM)$(FEATUREFLAG).gz
	Xplus.py $< $*.unk-scode-$(DIM)$(FEATUREFLAG).gz ${LENGTH} y | gzip > $@
%.XsubX$(FEATUREFLAG).gz: %.sub.gz $(X1) $(X2)
	concatSubs.py $< $(X1) $(X2) | gzip > $@
KNN=128 # number of nearest neighbors to compute
KNN_METRIC=4 # 0=euclid, 1=cosine 2=manhattan 3=maximum 4=jensen 5=zero-mean covariance
KNN_OPTIONS=-k ${KNN} -d ${KNN_METRIC} -p ${NCPU} -v
CYCLE=32

%.knn.gz: %.sub.gz 
	zcat $< | preinput.py | dists ${KNN_OPTIONS} | gzip > $@

%.knn128.gz: %.knn.gz %.words.gz
	zcat $< | awk '{printf("%s",$$1);for(i=2;i<=(128-1)*2;i+=2)printf(" %s",$$i);printf("\n")}' > $*.nn
	zcat $*.words.gz > $*.w
	paste $*.w $*.nn | awk '{for(i=2;i<=NF;i++)printf("%s\t%s\n",$$1,$$i)}' | splitknn.py ${LENGTH} | gzip > $@
	rm $*.nn $*.w

%.knn128: %.knn128.gz
	zcat $< > $@

%.knn.sc+f.gz: %.knn128 $(FEATFILE).feat.gz %.words.gz ../data/%.tok.gz
	head -$$(( ${CYCLE} * ${LENGTH} )) $< | add-features.pl -f $(FEATFILE).feat.gz | scode -t 0.001 -r 1 -d $(DIM) -z 0.166 -p 50 -u 0.2 -v -s $(SEED) | gzip > $@
%.knn.sc.gz: %.knn128 ../data/%.tok.gz
	head -$$(( ${CYCLE} * ${LENGTH} )) $< | scode -t 0.001 -r 1 -d $(DIM) -z 0.166 -p 50 -u 0.2 -v -s $(SEED) | gzip > $@

SHELL:=/bin/bash

%.knn.XY-raw$(FEATUREFLAG): %.knn.sc$(FEATUREFLAG).gz %.knn128
	zcat $< | average-and-norm.py -w <( head -$$(( ${CYCLE} * ${LENGTH} )) $*.knn128 ) -n ${LENGTH} --xy true | cut -f3-`echo $(DIM) | awk '{print $$1*2+2}'`> $@

%.knn.XY$(FEATUREFLAG).gz: %.knn.XY-raw$(FEATUREFLAG)  %.words.gz 
	zcat $*.words.gz > $*.words
	paste $*.words $< | gzip > $@
	rm $*.words
#___________________________________________________________________________________________
#EVALUATION ON POS INDUCTION - TODO AFTER +FEATURES

### K-Means Options
# KM_R=2
# KM_OPTIONS= -k 45 -r $(KM_R) -l -v -s $(SEED)

# UNK=

# %.type.embedded: %.$(UNK)type.gz %.words.gz %.pos.gz
# 	zcat $< > $*.typed
# 	concatSingle.py wsj.words.gz $*.typed > $@

# TOKEN_EMBED=
# %.token.embedded: %.$(TOKEN_EMBED).gz
# 	zcat $< > $@

# %.$(TOKEN_EMBED).eval: %.token.embedded
# 	cat $< | wkmeans ${KM_OPTIONS} > $*.clusters
# 	cat $*.clusters | tr -t ' ' '\t' | cut -f2 | eval.pl -m -v -g wsj.pos.gz 2> $@
# 	rm $*.clusters
# %.$(UNK)type.eval: %.type.embedded 
# 	cat $< | wkmeans ${KM_OPTIONS} > $*.clusters
# 	cat $*.clusters | tr -t ' ' '\t' | cut -f2 | eval.pl -m -v -g wsj.pos.gz 2> $@
# 	rm $*.clusters
#___________________________________________________________________________________________
clean: #TODO
	-rm -i *.lm.gz *.sub.gz *.knn.gz
	-rm *.*vocab.gz
	-rm *.*pairs.gz *.*scode.gz
	cd ../bin; make clean #TODO
	cd ../src; make clean #TODO

