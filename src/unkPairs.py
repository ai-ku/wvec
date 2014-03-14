#!/usr/bin/env python
usage='''
input format:
[1] gzipped wsub pairs file
[2] gzipped list of unknown words

output format:
stdout, wsub pairs, with unknown tag *UNKNOWN* for rare words
'''

import sys,gzip

if(len(sys.argv)<3):
    print usage
    sys.exit(0)

unk = set([l.strip() for l in gzip.open(sys.argv[2])])
for line in gzip.open(sys.argv[1]):
    l = line.strip().split()
    for i,w in enumerate(l):
        if w in unk:
            l[i] = '*UNKNOWN*'
    print '\t'.join(l)
