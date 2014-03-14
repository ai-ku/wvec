#!/usr/bin/env python
# ./getSuf.py *.seg.gz
import sys
import gzip
import re
from collections import defaultdict as dd

sufh = dd(int) 
wh = {}
for l in sys.stdin:
  l = l.decode('utf-8') 
  if l[0] == "#":
    continue
  larr = l.strip().split(" + ")
  (c, root) = larr[0].split()
  root = root.split('/')[0]
  for m in larr[1:]:
    w, p = m.split('/')
    root += w 
  larr = larr[:0:-1]
  suf = ""
  for m in larr:
    w, p = m.split('/')
    if p != "SUF":
      break
    suf = w + suf
  if len(suf) >= 2 and suf != "":
    sufh[suf] += 1 
  wh[root] = suf
  if suf != "":
    print "%s\t%s" % (root, suf)

words = {}
for l in gzip.open(sys.argv[1]):
  l = l.decode('utf-8') 
  words[l.strip()] = 1

for l in words.keys():
  for s, c in sorted(sufh.items(), key=lambda x: len(x[0]), reverse=True):
    if l not in wh and l.endswith(s):
      print "%s\t%s" % (l, s)
      break
##freq = dd(int)
##for l in words.keys():
##  for s, c in sorted(sufh.items()):
##    if l.endswith(s):
##      freq[s] += 1
##for l in words.keys():
##  for s, c in sorted(sufh.items(), key=lambda x: x[1], reverse=True):
##    if l.endswith(s):
##      print "%s\t%s" % (l, s)
##      break
