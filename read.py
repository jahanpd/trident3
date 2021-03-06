from google.cloud import bigquery
from pathlib import Path
import pydata_google_auth
from datetime import date, datetime
import simplejson as json
import pandas as pd
import numpy as np
import argparse
from tqdm import tqdm
from os import listdir
from os.path import isfile, join
import re

# helper function to interpret JSON
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))


def get_data(project_id, overwrite=[], dataset=[]):

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

    # MOVE TO MIMIC III
    if 'mimiciii' in dataset or 'both' in dataset:
        # create dataset and datatables for querying
        job_config = bigquery.job.QueryJobConfig()

        filtertable_mimiciii = Path('subscripts/mimiciii/filtertable.sql').read_text()
        filter_mimiciii = Path('subscripts/mimiciii/filter.sql').read_text().format(
            client.project
        )

        print("checking and adding filtertables")
        print("note, if you want to overwrite filtertable as well, you must specify it with 'filter'")
        dataset_id = "{}.trident".format(client.project)
        datasets = list(client.list_datasets())
        if 'trident' not in [dataset.dataset_id for dataset in datasets]:
            # Construct a full Dataset object to send to the API.
            dataset = bigquery.Dataset(dataset_id)
            dataset.location = "US"
            print("new dataset 'trident'created")
            dataset = client.create_dataset(dataset, timeout=30)

        del_filt = True if 'filter' in overwrite else False
        tables = client.list_tables(dataset_id)  # Make an API request.
        tables_ = [table.table_id for table in tables]
        if 'filtertable_mimiciii' not in tables_ or del_filt:
            print("adding filtertable for mimiciii")
            table_id = "{}.trident.{}".format(client.project, "filtertable_mimiciii")
            client.delete_table(table_id, not_found_ok=True)
            job_config = bigquery.QueryJobConfig(destination=table_id)
            query_job = client.query(filtertable_mimiciii, job_config=job_config)  # Make an API request.
            query_job.result()  # Wait for the job to complete.

        # mimiciii tables
        print("getting mimiciii tables")
        path = './subscripts/mimiciii/tables/'
        dest = './tables/mimiciii/'
        mimiciiitables = [(join(path, f), f.replace(".sql", "")) for f in listdir(path) if isfile(join(path, f))]
        mimiciiistored = [f.replace(".sql", "") for f in listdir(path) if isfile(join(path, f))]
        base_size = 0
        sizes = []
        tables = [table.replace("_mimiciii", "") for table in tables_ if 'mimiciii' in table]
        for query_path, f in mimiciiitables:
            if f not in tables or f in overwrite or 'all' in overwrite or f == 'base':
                try:
                    print("subsetting " + f)
                    table_id = "{}.trident.{}".format(client.project, "{}_mimiciii".format(f))
                    if f in overwrite or 'all' in overwrite or f == 'base':
                        client.delete_table(table_id, not_found_ok=True)
                    query = Path(query_path).read_text()
                    query = query.replace("FILTER_HERE", filter_mimiciii)
                    job_config = bigquery.QueryJobConfig(destination=table_id)
                    query_job = client.query(query, job_config=job_config)  # Make an API request.
                    result = query_job.result()
                    if f == 'base':
                        base_size = result.total_rows
                    else:
                        sizes.append((f, result.total_rows))
                except Exception as e:
                    print(f, e)

        if 'none' not in overwrite:
            for s in sizes:
                if s[1] != base_size:
                    print("{} is not the same size as base ({}) at {}".format(
                        s[0], base_size, s[1]
                    ))

        select = "SELECT \n base.* \n"
        from_ = "FROM {}.trident.{}_mimiciii as {}\n".format(client.project, "base", "base")
        base_select = ", {}.* EXCEPT (stay_id) \n"
        base_join = "LEFT JOIN {}.trident.{}_mimiciii as {} on {}.stay_id = base.stay_id \n"
        for f in [f for f in mimiciiistored if f != 'base']:
            from_ = from_ + base_join.format(
                client.project, f, f, f
            )
            select = select + base_select.format(f)
        fq = select + from_
        print("saving MIMICIII")

        query_mimiciii = client.query(fq)
        results = query_mimiciii.result()
        records = []
        print("getting mimic iii")
        pbar = tqdm(total=results.total_rows)
        for row in query_mimiciii:
            records.append(dict(row))
            pbar.update(1)
        pbar.close()
        json_data = json.dumps(records, default=json_serial, use_decimal=True)
        mimiciii = pd.read_json(json_data)
    else:
        mimiciii = None

    if 'mimiciv' in dataset or 'both' in dataset:
        # MOVE TO MIMIC IV
        filtertable_mimiciv = Path('subscripts/mimiciv/filtertable.sql').read_text()
        filter_mimiciv = Path('subscripts/mimiciv/filter.sql').read_text().format(
            client.project
        )

        job_config = bigquery.job.QueryJobConfig()

        print("checking and adding filtertables")

        del_filt = True if 'filter' in overwrite else False
        dataset_id = "{}.trident".format(client.project)
        tables = client.list_tables(dataset_id)  # Make an API request.
        tables_ = [table.table_id for table in tables]

        tables = client.list_tables(dataset_id)  # Make an API request.
        tables_ = [table.table_id for table in tables]
        if 'filtertable_mimiciv' not in tables_ or del_filt:
            print("adding filtertable for mimiciv")
            table_id = "{}.trident.{}".format(client.project, "filtertable_mimiciv")
            client.delete_table(table_id, not_found_ok=True)
            job_config = bigquery.QueryJobConfig(destination=table_id)
            query_job = client.query(filtertable_mimiciv, job_config=job_config)  # Make an API request.
            query_job.result()  # Wait for the job to complete.
        print("getting mimiciv tables")
        path = './subscripts/mimiciv/tables/'
        dest = './tables/mimiciv/'
        mimicivtables = [(join(path, f), f.replace(".sql", "")) for f in listdir(path) if isfile(join(path, f))]
        mimicivstored = [f.replace(".sql", "") for f in listdir(path) if isfile(join(path, f))]

        base_size = 0
        sizes = []
        tables = [table.replace("_mimiciv", "") for table in tables_ if 'mimiciv' in table]
        for query_path, f in mimicivtables:
            if f not in tables or f in overwrite or 'all' in overwrite or f == 'base':
                try:
                    print("subsetting " + f)
                    table_id = "{}.trident.{}".format(client.project, "{}_mimiciv".format(f))
                    if f in overwrite or 'all' in overwrite or f == 'base':
                        client.delete_table(table_id, not_found_ok=True)
                    query = Path(query_path).read_text()
                    query = query.replace("FILTER_HERE", filter_mimiciv)
                    job_config = bigquery.QueryJobConfig(destination=table_id)
                    query_job = client.query(query, job_config=job_config)  # Make an API request.
                    result = query_job.result()
                    if f == 'base':
                        base_size = result.total_rows
                    else:
                        sizes.append((f, result.total_rows))
                except Exception as e:
                    print(f, str(e))

        if 'none' not in overwrite:
            for s in sizes:
                if s[1] != base_size:
                    print("{} is not the same size as base ({}) at {}".format(
                        s[0], base_size, s[1]
                    ))

        select = "SELECT \n base.* \n"
        from_ = "FROM {}.trident.{}_mimiciv as {}\n".format(client.project, "base", "base")
        base_select = ", {}.* EXCEPT (stay_id) \n"
        base_join = "LEFT JOIN {}.trident.{}_mimiciv as {} on {}.stay_id = base.stay_id \n"
        for f in [f for f in mimicivstored if f != 'base']:
            from_ = from_ + base_join.format(
                client.project, f, f, f
            )
            select = select + base_select.format(f)
        fq = select + from_
        print("saving MIMICIV")

        query_mimiciv = client.query(fq)
        results = query_mimiciv.result()
        records = []
        print("getting mimic iv")
        pbar = tqdm(total=results.total_rows)
        for row in query_mimiciv:
            records.append(dict(row))
            pbar.update(1)
        pbar.close()
        json_data = json.dumps(records, default=json_serial, use_decimal=True)
        mimiciv = pd.read_json(json_data)
    else:
        mimiciv = None

    if 'both' in dataset:
        mimiciii_subset = mimiciii.loc[mimiciii['dbsource'] == 'carevue']
        seta = set(list(mimiciii))
        setb = set(list(mimiciv))
        cols = sorted(list(seta.intersection(setb)))
        mimic_combined = pd.concat([mimiciii_subset[cols], mimiciv[cols]], ignore_index=True)
    else:
        print('combined logic not implemented yet')
        mimic_combined = None

    return mimiciii, mimiciv, mimic_combined

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='input project id')
    parser.add_argument('--project_id', type=str, default='auspicious-silo-247823')
    parser.add_argument(
        '--overwrite', type=str, default=['none'], nargs='+',
        choices=[
            "aki", "base", "blood_products", "bloods", "comorbidites",
            "dt_output", "echo", "infection", "insulin", "pap", "ventilation",
            "vitals", "inotropes", "readmission", "filter", "fluids",
            "none", "all"
        ]
    )
    parser.add_argument(
        '--dataset', type=str, default=['both'], nargs='+',
        choices=["both", "mimiciii", "mimiciv"]
    )
    args = parser.parse_args()
    mimiciii, mimiciv, mimic_combined = get_data(
        args.project_id, args.overwrite, args.dataset)
    if mimiciii is not None:
        mimiciii.to_csv('mimiciii.csv', index=False)
    if mimiciv is not None:
        mimiciv.to_csv('mimiciv.csv', index=False)
    if mimic_combined is not None:
        mimic_combined.to_csv('mimic_combined.csv', index=False)
