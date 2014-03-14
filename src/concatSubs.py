#!/usr/bin/env python
usage='''
input

[1] sub.gz file
[2] gzipped target word embedding
[3] gzipped ctx word embeddings

output
stdout, word, embedding size of [2]+[3], [4] many number of lines
'''

import sys,gzip,math


if len(sys.argv) != 4:
    print usage
    sys.exit(1)

def readEmbed(infile):
    d = {}
    for line in gzip.open(infile):
        l = line.strip().split()
        emb = [float(v) for v in l[1:]]
        if len(sys.argv) == 6 and l[0] != "*UNKNOWN*":
            d[l[0].lower()] = emb
        else:
            d[l[0]] = emb
    return d

targetD = readEmbed(sys.argv[2])
contextD = readEmbed(sys.argv[3])

def subNormalize(subline):
    tokens = subline[0::2]
    logp = subline[1::2]

    total = 0
    for l in logp:
        total += math.e**float(l)
    prob = [(math.e**float(l))/total for l in logp]

    return tokens, prob

DIM = len(contextD["*UNKNOWN*"])
print >> sys.stderr, DIM

it = 0
for li,line in enumerate(gzip.open(sys.argv[1])):
    l = line.strip().split()
    if l[0] == "</s>":
        if it % 200 == 0:
            print >> sys.stderr, it,".",
        if it % 1000 == 0:
            print >> sys.stderr
        it += 1
        continue
    target = l[0]
    tokens,prob = subNormalize(l[1:])

    if target not in targetD:
        target = "*UNKNOWN*"

    cval = [0]*DIM
    for j,(token,coef) in enumerate(zip(tokens,prob)):
        if token not in contextD:
            token = "*UNKNOWN*"
        for i,dim in enumerate(contextD[token]):
            cval[i] += dim*coef

    outv = targetD[target] + cval
    stringout = [str(o) for o in outv]
    print l[0],'\t'.join(stringout)

print >> sys.stderr, "!"
