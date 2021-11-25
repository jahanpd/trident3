import pandas as pd
import numpy as np

# mimic iii tests
data = pd.read_csv("mimiciii.csv")
print(data)
for c in list(data):
    # view missingness
    missing = max(
        np.sum(np.isna(data[c].values)),
        np.sum(data[c].values == '[]')
    )
