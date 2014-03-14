#!/usr/bin/env python
usage='''
input format:
[1] gzipped wsub pairs file
[2] gzipped scode output
[3] # of line in test file
[4] option { x | y }  
 x : concat word vectors
 y : concat context vectors

output format:
stdout, <word  wordEmbedding > word embedding size of [2]+[2], [3] many number of lines
'''

import sys,gzip

if(len(sys.argv)<5):
    print usage
    sys.exit(0)

def readEmbed(infile,opt):
    d = {}
    for line in gzip.open(infile):
        if not opt in line:
            continue
        l = line.strip().split(opt)[1].split()
        emb = [float(v) for v in l[2:]]
        d[l[0]] = emb
    return d

L = int(sys.argv[3])
targetD = readEmbed(sys.argv[2],'0:')
OPT=['1:','0:']
contextD = readEmbed(sys.argv[2],OPT[sys.argv[4] == 'x'])


pairD = {}
K = 0
for i,line in enumerate(gzip.open(sys.argv[1])):
    l = line.strip().split()

    target = l[0]
    context = l[1]
    j = i%L

    if target not in targetD:
        target = "*UNKNOWN*"
    if context not in contextD:
        context = "*UNKNOWN*"
    if (j,target) not in pairD:
        pairD.setdefault((j,target),[])

    pairD[(j,target)].append(contextD[context])
    if j == 0:
        K += 1
for i,line in enumerate(gzip.open(sys.argv[1])):
    if i == L:
        break
    l = line.strip().split()

    target = l[0]
    if target not in targetD:
        target = "*UNKNOWN*"

    cval = []
    for j in xrange(len(pairD[(i,target)][0])):
        vsum = 0
        for k in xrange(K):
            vsum += pairD[(i,target)][k][j]

        cval.append(vsum*1.00/K)
    outv = targetD[target] + cval
    stringout = [str(o) for o in outv]
    print l[0],'\t'.join(stringout)
