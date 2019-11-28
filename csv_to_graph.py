#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re
import math

def retrieveNoThreadsFromFilename(filename):
    return re.match('.*(\d{2})threads\.csv', filename).group(1)

types = [ "file-logged", "noop", "jaeger", "vanilla", "tracing-off" ]
rgbTriples = { "file-logged" : "255, 25, 25", "noop" : "25, 25, 255", "jaeger" : "25, 255, 25", "vanilla" : "25, 25, 25", "tracing-off" : "240, 240, 25"  }

def assignRgbTriple(t):
    if t in rgbTriples:
        return "rgb(" + rgbTriples[t] + ")"
    else:
        raise ValueError("got weird Narayana type " + t)

def typeFromFilename(filename):
    typeCand = re.match('.*\/(.*)\-\d{2}threads\.csv', filename).group(1)
    if typeCand in types:
        return typeCand
    else:
        raise ValueError("got weird filename " + filename)

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing at least one input csv file")

fig = go.Figure()
scores=[]
threads=[]
names=[]
narayanaType=None
lastSeenNarayana=typeFromFilename(sys.argv[1])

for f in sorted(sys.argv[1:]):
    csv = pd.read_csv(f)
    narayanaType = typeFromFilename(f)
    if(narayanaType != lastSeenNarayana):
        print("names=" + str(names) + ", threads=" + str(threads) + ", scores=" + str(scores))  
        fig.add_trace(go.Scatter(name=lastSeenNarayana, x=threads, y=scores, marker_color=assignRgbTriple(lastSeenNarayana)))
        scores=[]
        threads=[]
        names=[]
        lastSeenNarayana=narayanaType
    # Benchmark contains fully qualified test class names, let's trim them out a bit
    names += [ '/'.join(b.split('.')[-2:]) for b in csv['Benchmark'] ]
    threads += [math.log(int(retrieveNoThreadsFromFilename(f)), 2)]
    scores += list(csv['Score'])

fig.add_trace(go.Scatter(name=narayanaType, x=threads, y=scores, marker_color=assignRgbTriple(narayanaType)))
fig.update_layout(title=names[0], xaxis_title="no. threads, log x", yaxis_title="score")
fig.show()

