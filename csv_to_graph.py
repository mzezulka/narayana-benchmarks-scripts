#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re
import math
from plotly.subplots import make_subplots

types = [ "file-logged", "noop", "jaeger", "vanilla", "tracing-off" ]
rgbTriples = { "file-logged" : "254, 232, 200", "noop" : "254, 232, 200", "jaeger" : "227, 74, 51", "vanilla" : "253, 187, 132", "tracing-off" : "254, 232, 200"  }

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
        # Benchmark contains fully qualified test class names, let's trim the name a bit
        name = '/'.join(name.split('.')[-1:])
        if(name != "twoPhaseCommit"):
            continue
        dataTriples[lastSeenNarayana].append((name, threads, score))
        if name not in namesMap.keys(): 
            namesMap[name] = highestColIndex
            highestColIndex += 1

fig = make_subplots(
        rows=len(namesMap.keys()),
        shared_xaxes=True,
        cols=1,
        subplot_titles=list(namesMap.keys()),
        x_title="Number of Threads (-t JMH arg)",
        y_title="Operations Per Second")
dotSize = 10
for narayanaType in dataTriples.keys():
    oneType = dataTriples[narayanaType]
    if(oneType is None or len(oneType) == 0):
        print("Empty result set for '" + narayanaType + "', skipping...")
        continue
    (name, threads, score) = oneType[0]
    fig.add_trace(go.Bar(
                     x=[threads],
                     y=[score],
                     name=narayanaType,
                     legendgroup=narayanaType,
                     # marker_size=dotSize,
                     marker_color=assignRgbTriple(narayanaType)),
                     row=namesMap[name],
                     col=1)
    for (name, threads, score) in oneType[1:]:
       fig.add_trace(go.Bar(
                        showlegend=False,
                        x=[threads],
                        y=[score],
                        name=narayanaType,
                        legendgroup=narayanaType,
                        # marker_size=dotSize,
                        marker_color=assignRgbTriple(narayanaType)),
                        row=namesMap[name],
                        col=1)

fig.update_xaxes(type="category")
fig.update_yaxes(type="log")
fig.update_layout(
    barmode='group',
    width=800,
    font=dict(
        family="Arial",
        size=12,
        color="#1f1f1f"
    )
)
fig.show()

