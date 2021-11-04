import pandas as pd
import pandas_gbq
from pathlib import Path
import argparse

def get_data(project_id):
    sql_iii = Path('mimic-iii.sql').read_text()
    sql_iv = Path('mimic-iv.sql').read_text()

    mimiciv = pandas_gbq.read_gbq(sql_iv, project_id=project_id)
    mimiciii = pandas_gbq.read_gbq(sql_iii, project_id=project_id)
    
    mimiciii_subset = mimiciii.loc[mimiciii['dbsource'] == 'carevue']

    seta = set(list(mimiciii))
    setb = set(list(mimiciv))
    cols = list(seta.intersection(setb))
    mimic_combined = pd.concat([mimiciii_subset[cols], mimiciv[cols]], ignore_index=True)
    return mimiciii, mimiciv, mimic_combined

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='input project id')
    parser.add_argument('project_id', type=str, default='auspicious-silo-247823')
    args = parser.parse_args()
    mimiciii, mimiciv, mimic_combined = get_data(args.project_id)
    mimiciii.to_csv('mimiciii.csv')
    mimiciv.to_csv('mimiciv.csv')
    mimic_combined.to_csv('mimic_combined.csv')