#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re
import math
from plotly.subplots import make_subplots

types = [ "file-logged", "noop", "jaeger", "vanilla", "tracing-off" ]
rgbTriples = { "file-logged" : "255,255,191", "noop" : "255,255,191", "jaeger" : "252,141,89", "vanilla" : "145,191,219", "tracing-off" : "255,255,191"  }

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

def assignType(narayanaType):
    if(narayanaType == "vanilla"):
        return "T5"
    elif(narayanaType == "tracing-off"):
        return "T4"
    elif(narayanaType == "noop"):
        return "T3"
    elif(narayanaType == "jaeger"):
        return "T2"
    elif(narayanaType == "file-logged"):
        return "T1"

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing at least one input csv file")

narayanaType=None
lastSeenNarayana=typeFromFilename(sys.argv[1])
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

fig = make_subplots(
        rows=3,
        shared_xaxes=True,
        subplot_titles=("Number of Threads = 1", "Number of Threads = 2", "Number of Threads = 4"),
        cols=1,
        x_title="Narayana Type",
        y_title="Operations Per Second")
for narayanaType in dataTriples.keys():
    oneType = dataTriples[narayanaType]
    if(oneType is None or len(oneType) == 0):
        print("Empty result set for '" + narayanaType + "', skipping...")
        continue
    (name, threads, score) = oneType[0]
    narayanaTypeMethod=assignType(narayanaType)
    fig.add_trace(go.Bar(
                     x=[narayanaTypeMethod],
                     y=[score],
                     y0=0,
                     name=str(threads),
                     marker_color=assignRgbTriple(narayanaType)),
                     row=int(math.log(threads,2)) + 1,
                     col=1)
    for (name, threads, score) in oneType[1:]:
       fig.add_trace(go.Bar(
                        x=[narayanaTypeMethod],
                        y=[score],
                        y0=0,
                        name=str(threads),
                        legendgroup=narayanaTypeMethod,
                        marker_color=assignRgbTriple(narayanaType)),
                        row=int(math.log(threads,2)) + 1,
                        col=1)

fig.update_xaxes(type="category")
fig.update_yaxes(type="log")
fig.update_yaxes(ticks="outside", tickwidth=2, tickcolor='crimson', ticklen=10, col=1)
fig.update_layout(
    barmode='group',
    width=700,
    font=dict(
        family="Arial",
        size=12,
        color="#1f1f1f"
    ),
    showlegend=False
)
fig.show()
