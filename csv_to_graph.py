#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re
import math
from plotly.subplots import make_subplots

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

fig = make_subplots(rows=1, cols=5)
namesMap={}
narayanaType=None
lastSeenNarayana=typeFromFilename(sys.argv[1])
highestColIndex=1

for f in sorted(sys.argv[1:]):
    narayanaType = typeFromFilename(f)
    if(narayanaType != lastSeenNarayana):
        lastSeenNarayana=narayanaType
    for line in pd.read_csv(f).groupby(["Benchmark", "Threads", "Score"]):
        (name, threads, score) = line[0]
        logThreads = math.log(int(threads), 2)
        # Benchmark contains fully qualified test class names, let's trim the name a bit
        name = '/'.join(name.split('.')[-2:])
        if name not in namesMap.keys(): 
            namesMap[name] = highestColIndex
            highestColIndex += 1
        fig.add_trace(go.Scatter(x=[logThreads], y=[score], name=narayanaType, marker_color=assignRgbTriple(lastSeenNarayana)), row=1, col=namesMap[name])
        fig.update_layout(xaxis_title="no. threads, binary log", yaxis_title="score")

fig.show()

