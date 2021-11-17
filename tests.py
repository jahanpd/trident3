import pandas as pd
import numpy as np

# mimic combined tests

# import data
data = pd.read_csv("mimic_combined.csv")

print(list(data))
# check missingness from drain tubes
ratio = len(data[data.dtoutput == '[]']) / len(data)
print("Drain tube missing ratio: {}".format(ratio))
