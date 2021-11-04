# Trident III Intensive - Data extraction repository

This repository houses 2 twin extraction scripts in bigquery sql for the mimic databases.
You can copy and paste them into the bigquery console in a browser and download the data there.
Alternatively, you can use the read.py python script to download the data.
This approach will automatically combine the two datasets into a third combo dataset across the common columns in the datasets.
This datasets will be downloaded and saved into the folder where the script is run.

To use this script, follow the instructions below (will differ for windows but be broadly similar).

## Requirements
- Git installed
- Python version 3.9.7 (or near enough, ie 3.9+)
- Current access to the mimic databases through bigquery
- On the bigquery platform, locate the project_id through which you access the physionet-data
- Working knowledge of using your terminal / shell will help

## Instructions
1. Clone this repository and cd into the directory.
```console
foo@bar:~$ git clone https://github.com/jahanpd/trident3.git
foo@bar:~$ cd trident3
foo@bar: trident3 $
```
2. Create a python virtualenv and install dependencies
```console
foo@bar: trident3 $ python -m venv venv
foo@bar: trident3 $ source venv/bin/activate
(venv) foo@bar: trident3 $ pip install -r requirements.txt
```
3. Run the script read.py with your project_id as the main argument.
```console
(venv) foo@bar: trident3 $ python read.py example-projectid-1234
```
4. You will be directed at some stage to allow access / log in as per the [pandas-gbq package](https://pandas-gbq.readthedocs.io/en/latest/intro.html#authenticating-to-bigquery)
5. Get a coffee and have PATIENCE. The final dataset sizes are approx 485MB, 372MB, and 719MB for mimiciii, mimiciv, and combined respectively. It can take a while to run the script and download them.