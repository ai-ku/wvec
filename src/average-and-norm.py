#!/usr/bin/env python

from collections import defaultdict
from itertools import count, izip
from optparse import OptionParser
import sys

parser = OptionParser()
parser.add_option('-x', '--xy', dest='xy')
parser.add_option('-w', '--wordsub', dest='ws_file')
parser.add_option('-n', '--length', dest='length')
options, args = parser.parse_args()

ws_file = options.ws_file
length  = int(options.length)

assert ws_file

xy = False
if options.xy == 'true':
    xy = True

left  = {}
right = {}
words = ['' for i in xrange(length)]
subs  = [[] for i in xrange(length)]

for line in sys.stdin:
    l = line[2:].split()
    if line.startswith('1:'):
        right[l[0]] = map(float, l[2:])
    else:
        left[l[0]] = '\t'.join(l[2:])

for line, c in izip(open(ws_file), count()):
    line = line.split()
    words[c % length] = line[0]
    subs[c % length].append(line[1])

for w, sub, c in izip(words, subs, count()):
    # average
    res = [0.0 for i in xrange(len(right[sub[0]]))]
    for s in sub:
        v = right[s]
        for i in xrange(len(res)):
            res[i] += v[i]

    # norm
    l   = sum(map(lambda x: x * x, res)) ** 0.5
    res = '\t'.join(map(lambda x: str(x / l), res))

    if xy:
        print '%d\t1\t%s\t%s' % (c, left[w], res)
    else:
        print '%d\t1\t%s' % (c, res)

