#!/usr/bin/env bash
set -euo pipefail

echo "▶ Installation des dépendances du lab…"

# Airflow nécessite un fichier de contraintes pour une install reproductible
AIRFLOW_VERSION=2.10.4
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINTS="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install --upgrade pip
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINTS}"
pip install -r requirements.txt

# Airflow pointe sur le dossier dags du repo
export AIRFLOW_HOME="${PWD}/airflow"
echo "export AIRFLOW_HOME=${PWD}/airflow" >> ~/.bashrc

# dbt trouve profiles.yml dans le dossier dbt/ (sinon il le cherche dans ~/.dbt)
echo "export DBT_PROFILES_DIR=${PWD}/dbt" >> ~/.bashrc

echo "✅ Lab prêt. Voir le README pour le démarrage rapide."
