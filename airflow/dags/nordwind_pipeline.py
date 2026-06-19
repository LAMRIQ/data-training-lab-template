"""
DAG d'orchestration du capstone Nordwind : ingestion -> dbt run -> dbt test.

3 tâches en BashOperator pour que le junior VOIE exactement les commandes qu'il a
tapées à la main (python ingestion/load_raw.py, puis dbt run, puis dbt test).
L'idempotence vient de `CREATE OR REPLACE` côté ingestion (load_raw.py) et de la
reconstruction dbt à chaque run — un re-run ne duplique rien.

Pour un incrémental par date (gros volumes), on paramétrerait par {{ ds }}
(delete de la partition du jour + insert) ; ici le dataset est petit, on full-refresh.
"""

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.bash import BashOperator

PROJECT_ROOT = Path(__file__).resolve().parents[2]


def alerte_echec(context):
    """Callback d'alerte : rendre l'échec VISIBLE. Ici un log ; en prod, Slack/mail."""
    ti = context["task_instance"]
    print(f"❌ ALERTE : la tâche {ti.task_id} du DAG {ti.dag_id} a échoué.")


default_args = {
    "owner": "data-training-lab",
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
    "on_failure_callback": alerte_echec,
}

with DAG(
    dag_id="nordwind_pipeline",
    description="Capstone Nordwind : ingestion + transformation dbt (run + test)",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["capstone", "elt", "nordwind"],
) as dag:

    load_raw = BashOperator(
        task_id="load_raw",
        bash_command=f"cd {PROJECT_ROOT} && python ingestion/load_raw.py",
    )

    # `--profiles-dir .` : le profil dbt est dans dbt/ (comme le Makefile). Robuste même si
    # DBT_PROFILES_DIR n'est pas dans l'environnement du scheduler.
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {PROJECT_ROOT}/dbt && dbt run --profiles-dir .",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {PROJECT_ROOT}/dbt && dbt test --profiles-dir .",
    )

    load_raw >> dbt_run >> dbt_test
