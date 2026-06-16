"""
DAG d'orchestration : ingestion → dbt build (staging + marts + tests).
Volontairement simple — on utilise BashOperator pour que le junior VOIE les commandes
qu'il a déjà lancées à la main. L'idempotence vient de `CREATE OR REPLACE` / `dbt build`.
"""

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.bash import BashOperator

PROJECT_ROOT = Path(__file__).resolve().parents[2]

default_args = {
    "owner": "data-training-lab",
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}

with DAG(
    dag_id="elt_pipeline",
    description="Pipeline e-commerce : ingestion + transformation dbt",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["capstone", "elt"],
) as dag:

    ingest = BashOperator(
        task_id="ingest_raw",
        bash_command=f"cd {PROJECT_ROOT} && python ingestion/load_raw.py",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {PROJECT_ROOT}/dbt && dbt build",
    )

    ingest >> dbt_build
