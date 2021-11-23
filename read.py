from google.cloud import bigquery
from pathlib import Path
import pydata_google_auth
from datetime import date, datetime
import simplejson as json
import pandas as pd
import argparse
from tqdm import tqdm
from os import listdir
from os.path import isfile, join

# helper function to interpret JSON
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))


def get_data(project_id, overwrite=[]):

    # set up authentication
    SCOPES = [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/drive',
    ]

    credentials = pydata_google_auth.get_user_credentials(
        SCOPES,
        # Set auth_local_webserver to True to have a slightly more convienient
        # authorization flow. Note, this doesn't work if you're running from a
        # notebook on a remote sever, such as over SSH or with Google Colab.
        auth_local_webserver=True,
    )

    client = bigquery.Client(project=project_id, credentials=credentials)

    # create dataset and datatables for querying
    job_config = bigquery.job.QueryJobConfig()

    filtertable_mimiciii = Path('subscripts/mimiciii/filtertable.sql').read_text()
    filter_mimiciii = Path('subscripts/mimiciii/filter.sql').read_text().format(
        client.project
    )
    filtertable_mimiciv = Path('subscripts/mimiciv/filtertable.sql').read_text()
    filter_mimiciv = Path('subscripts/mimiciv/filter.sql').read_text().format(
        client.project
    )

    print("checking and adding filtertables")
    dataset_id = "{}.trident".format(client.project)
    datasets = list(client.list_datasets())
    if 'trident' not in [dataset.dataset_id for dataset in datasets]:
        # Construct a full Dataset object to send to the API.
        dataset = bigquery.Dataset(dataset_id)
        dataset.location = "US"
        print("new dataset 'trident'created")
        dataset = client.create_dataset(dataset, timeout=30)

    tables = client.list_tables(dataset_id)  # Make an API request.
    if 'filtertable_mimiciii' not in [table.table_id for table in tables]:
        print("adding filtertable for mimiciii")
        table_id = "{}.trident.{}".format(client.project, "filtertable_mimiciii")
        job_config = bigquery.QueryJobConfig(destination=table_id)
        query_job = client.query(filtertable_mimiciii, job_config=job_config)  # Make an API request.
        query_job.result()  # Wait for the job to complete.

    # mimiciii tables
    print("getting mimiciii tables")
    path = './subscripts/mimiciii/tables/'
    dest = './tables/mimiciii/'
    mimiciiitables = [(join(path, f), f.replace(".sql", "")) for f in listdir(path) if isfile(join(path, f))]
    mimiciiistored = [f.replace(".csv", "") for f in listdir(dest) if isfile(join(dest, f))]
    print(mimiciiistored)
    for query_path, f in mimiciiitables:
        if f not in mimiciiistored or f in overwrite or 'all' in overwrite:
            print("subsetting " + f)
            query = Path(query_path).read_text()
            query = query.replace("FILTER_HERE", filter_mimiciii)
            query_job = client.query(query)  # Make an API request.
            records = []
            pbar = tqdm(total=8000)
            for row in query_job:
                records.append(dict(row))
                pbar.update(1)
            json_data = json.dumps(records, default=json_serial, use_decimal=True)
            table = pd.read_json(json_data)
            table.to_csv("{}{}.csv".format(dest, f), index=False)

    #records = []
    #print("getting mimic iii")
    #pbar = tqdm(total=8000)
    #for row in query_mimiciii:
    #    records.append(dict(row))
    #    pbar.update(1)
    #json_data = json.dumps(records, default=json_serial, use_decimal=True)
    #mimiciii = pd.read_json(json_data)

    #query_mimiciv = client.query(sql_iv, job_config=job_config)  # Make an API request.
    #records = []
    #print("getting mimic iv")
    #pbar = tqdm(total=8000)
    #for row in query_mimiciv:
    #    records.append(dict(row))
    #    pbar.update(1)
    #json_data = json.dumps(records, default=json_serial, use_decimal=True)
    #mimiciv = pd.read_json(json_data)

    #mimiciii_subset = mimiciii.loc[mimiciii['dbsource'] == 'carevue']
    #seta = set(list(mimiciii))
    #setb = set(list(mimiciv))
    #cols = list(seta.intersection(setb))
    #mimic_combined = pd.concat([mimiciii_subset[cols], mimiciv[cols]], ignore_index=True)
    return mimiciii, mimiciv, mimic_combined

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='input project id')
    parser.add_argument('project_id', type=str, default='auspicious-silo-247823')
    parser.add_argument(
        '--overwrite', type=str, default='none', nargs='+',
        choices=[
            "aki", "base", "blood_products", "bloods", "comorbidites",
            "dt_output", "echo", "infection", "insulin", "pap", "ventilation",
            "vitals",
            "none", "all"
        ]
    )
    args = parser.parse_args()
    mimiciii, mimiciv, mimic_combined = get_data(args.project_id, args.overwrite)
    mimiciii.to_csv('mimiciii.csv')
    mimiciv.to_csv('mimiciv.csv')
    mimic_combined.to_csv('mimic_combined.csv')
