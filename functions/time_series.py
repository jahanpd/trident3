import json
import datetime

def to_statistic(array, starttime, duration, statistic):
    """
        Processing function to take a time series array
        and convert it to a summary statistic over that
        time period.
        ARGS:
            array: str, json array to be processed
            starttime: str, one of 'intime' or 'postop_intime'
            duration: int, hours after startime to record array
            statistic: one of mean, min, max
    """
    array = json.loads(array.replace("'", '"'))
