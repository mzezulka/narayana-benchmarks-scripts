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
    typeCand = re.match('.*\/(.*)\-\d{1,2}threads\.csv', filename).group(1)
    if typeCand in types:
        return typeCand
    else:
        raise ValueError("got weird filename " + filename)

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing at least one input csv file")

namesMap={}
narayanaType=None
lastSeenNarayana=typeFromFilename(sys.argv[1])
highestColIndex=1
dataTriples={}
dataTriples[lastSeenNarayana]=[]

for f in sorted(sys.argv[1:]):
    narayanaType = typeFromFilename(f)
    if(narayanaType != lastSeenNarayana):
        lastSeenNarayana=narayanaType
        dataTriples[lastSeenNarayana] = []
    for line in pd.read_csv(f).groupby(["Benchmark", "Threads", "Score"]):
        (name, threads, score) = line[0]
        threads = math.log(int(threads), 2)
        # Benchmark contains fully qualified test class names, let's trim the name a bit
        name = '/'.join(name.split('.')[-2:])
        dataTriples[lastSeenNarayana].append((name, threads, score))
        if name not in namesMap.keys(): 
            namesMap[name] = highestColIndex
            highestColIndex += 1

fig = make_subplots(rows=1, cols=len(namesMap.keys()), subplot_titles=list(namesMap.keys()))
dotSize = 16
for narayanaType in dataTriples.keys():
    oneType = dataTriples[narayanaType]
    if(oneType is None or len(oneType) == 0):
        print("Empty result set for '" + narayanaType + "', skipping...")
        continue
    (name, threads, score) = oneType[0]
    fig.add_trace(go.Scatter(x=[threads], y=[score], name=narayanaType, legendgroup=narayanaType, marker_size=dotSize, marker_color=assignRgbTriple(narayanaType)), row=1, col=namesMap[name])
    for (name, threads, score) in oneType[1:]:
       fig.add_trace(go.Scatter(showlegend=False, x=[threads], y=[score], name=narayanaType, legendgroup=narayanaType, marker_size=dotSize, marker_color=assignRgbTriple(narayanaType)), row=1, col=namesMap[name])

fig.show()

