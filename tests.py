import pandas as pd
import numpy as np

# mimic iii tests
m3 = pd.read_csv("mimiciii.csv")
m4 = pd.read_csv("mimiciv.csv")

m3c = set(list(m3))
m4c = set(list(m4))

print(m3c.difference(m4c))
print(m4c.difference(m3c))

print("mimic iii diagnostics")
for c in list(m3):
    # view missingness
    try:
        missing = np.sum(np.isnan(m3[c].values))
    except:
        missing = np.sum(np.sum(m3[c].values == '[]'))
    try:
        mean = np.nanmean(m3[c].values)
    except:
        mean = "ar"
    print(c, "missing: {}/{}, mean:{}".format(
        missing, len(m3), mean
    ))

print("mimic iv diagnostics")
for c in list(m4):
    # view missingness
    try:
        missing = np.sum(np.isnan(m4[c].values))
    except:
        missing = np.sum(np.sum(m4[c].values == '[]'))
    try:
        mean = np.nanmean(m4[c].values)
    except:
        mean = "ar"
    print(c, "missing: {}/{}, mean:{:f2}".format(
        missing, len(m4), mean
    ))

