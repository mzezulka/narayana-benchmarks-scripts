#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing the input csv file")

filename = sys.argv[1]
# 10 and 50 are for backwards compatibility with the previous tests
shades = { "01" : 225, "02" : 195, "04" : 165, "08" : 135, "10", 135, "16" : 105, "32" : 75, "50" : 75, "64" : 45, "128" : 15 }

def retrieveNoThreadsFromFilename(filename):
    return re.match('.*(\d{2})threads\.csv', filename).group(1)

def shadeFromFilename(filename):
    print(filename)
    return shades[retrieveNoThreadsFromFilename(filename)]

def assignRgbTriple(filename):
    shade = str(shadeFromFilename(filename))
    if("file-logged" in filename):
        return "rgb(255, " + shade + ", " + shade + ")"
    elif("noop" in filename):
        return "rgb(" + shade + ", " + shade + ", 255)"
    elif("jaeger" in filename):
        return "rgb(" + shade + ", 255, " + shade + ")"
    elif("vanilla" in filename):
        return "rgb(" + shade + ", " + shade + ", " + shade + ")"
    elif("tracing-off" in filename):
        return "rgb(255, 255, " + shade + ")"
    else:
        raise ValueError("got weird filename " + filename)

df = pd.read_csv(filename)
fig = go.Figure()
scores=[]
threads=[]
names=[]
colors=[]
for f in sys.argv[1:]:
    csv = pd.read_csv(f)
    scores += list(csv['Score'])
    # Benchmark contains fully qualified test class names, let's trim them out a bit
    names_aux = [ '/'.join(b.split('.')[-2:]) for b in csv['Benchmark'] ]
    threads += [int(retrieveNoThreadsFromFilename(f))] * len(names_aux)
    names += names_aux
    colors += [assignRgbTriple(f)] * len(names_aux)

go.Figure(data=[go.Scatter3d(x=names, y=threads, z=scores, mode='markers', marker=dict(size=6, color=colors, colorscale="Viridis", opacity=0.8))]).show()


