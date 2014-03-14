#!/usr/bin/env python

import sys

length = int(sys.argv[1])

lines = sys.stdin.readlines()

n = len(lines) / length
for i in xrange(n):
    for j in xrange(length):
        sys.stdout.write(lines[i + j * n])
