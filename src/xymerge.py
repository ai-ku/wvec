#!/usr/bin/env python

from collections import defaultdict
from optparse import OptionParser
import sys

parser = OptionParser()
parser.add_option('-w', '--wordsub', dest='ws_file')
options, args = parser.parse_args()

ws_file = options.ws_file

assert ws_file

left  = {}
right = {}
for line in sys.stdin:
    add_to = left
    if line.startswith('1:'):
        add_to = right
    line = line[2:].split()
    add_to[line[0]] = '\t'.join(line[2:])

left_right = defaultdict(int)
for line in open(ws_file):
    ws = line.split()
    left_right[(ws[0], ws[1])] += 1

for (w, s), c in left_right.iteritems():
    print '%s_%s\t%d\t%s\t%s' % (w, s, c, left[w], right[s])
