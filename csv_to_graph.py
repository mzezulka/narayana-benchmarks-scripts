#!/usr/bin/env python3
# required dependencies: plotly, pandas

import pandas as pd
import plotly.graph_objects as go
import sys

if(len(sys.argv) < 2):
    raise ValueError("expected exactly one argument representing the input csv file")

filename = sys.argv[1]

df = pd.read_csv(filename)
fig = go.Figure()

for f in sys.argv[1:]:
    df = pd.read_csv(f)
    # Benchmark contains fully qualified test class names, let's trim them out a bit
    df['Benchmark'] = [ '/'.join(b.split('.')[-2:]) for b in df['Benchmark'] ]
    fig.add_trace(go.Bar(x = df['Benchmark'], y = df['Score'], name=f))

fig.show()


