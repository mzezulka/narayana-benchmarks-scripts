#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys
import re

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing the input csv file")

filename = sys.argv[1]
shades = { "01" : 225, "02" : 180, "04" : 135, "10" : 90, "50" : 45 }

def shadeFromFilename(filename):
    print(filename)
    m = re.match('.*(\d{2})threads\.csv', filename)
    return shades[m.group(1)]

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

for f in sys.argv[1:]:
    df = pd.read_csv(f)
    # Benchmark contains fully qualified test class names, let's trim them out a bit
    df['Benchmark'] = [ '/'.join(b.split('.')[-2:]) for b in df['Benchmark'] ]
    fig.add_trace(go.Bar(x = df['Benchmark'], y = df['Score'], name=f, marker_color=assignRgbTriple(f)))

fig.show()


