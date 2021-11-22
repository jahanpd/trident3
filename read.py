from google.cloud import bigquery
from pathlib import Path
import pydata_google_auth
from datetime import date, datetime
import simplejson as json
import pandas as pd

# helper function to interpret JSON
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))


def get_data(project_id):
    sql_iii = Path('mimic-iii.sql').read_text()
    sql_iv = Path('mimic-iv.sql').read_text()

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

    job_config = bigquery.job.QueryJobConfig()

    query_mimiciii = client.query(sql_iii, job_config=job_config)  # Make an API request.
    records = [dict(row) for row in query_mimiciii]
    json_data = json.dumps(records, default=json_serial, use_decimal=True)
    mimiciii = pd.read_json(json_data)

    query_mimiciv = client.query(sql_iv, job_config=job_config)  # Make an API request.
    records = [dict(row) for row in query_mimiciv]
    json_data = json.dumps(records, default=json_serial, use_decimal=True)
    mimiciv = pd.read_json(json_data)

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
