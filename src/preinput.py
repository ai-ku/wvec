#!/usr/bin/python

import struct
import sys
import math
import gzip

def input_preprocess():
    voc = {}
    cov = {}
#    df = open(fname + ".word", "w")
    count = 0;
    li = 0;
    for line in sys.stdin:
        l = line.strip().split()
        templ=l
        li+=1
        word = l.pop(0)
        if word == "</s>" or word == "</S>":           
            continue
        elif voc.get(word) == None:
            voc[word] = len(voc)
            cov[voc[word]] = word
        count += 1
#        df.write(word + " " + str(voc[word]) + "\n");
        row = {}
        nnz = len(l)/2
#        if len(l) == 199:
#            print >> sys.stderr, len(l),li
#            print >> sys.stderr, "word:", word," ".join(templ)
        for i in range(0,nnz):
            if voc.get(l[2 * i]) == None:
                voc[l[2 *i]] = len(voc)
                cov[voc[l[2 *i]]] = l[2 * i]
            wid = voc[l[2 * i]]
            row[wid] = math.pow(10, float(l[2 * i + 1]))
        skey = sorted(row.keys())
        rowSum = sum(row.values())
        print nnz,
        checkSum = 0
        for sub in skey:
            checkSum += row[sub]*1.0/rowSum
            print sub,row[sub]*1.0/rowSum,
#        print " sum", checkSum
        print
#        if li >30:
#            sys.exit(1)
#    vf = open(fname + ".voc", "w")
#    for ww in cov:
#        vf.write("{0} {1}\n".format(cov[ww], ww))
#    vf.close()
#    df.close()
#    print >> sys.stderr, "NumberOfLines:",count,

input_preprocess()
