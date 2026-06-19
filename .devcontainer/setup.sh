#!/usr/bin/env bash
set -euo pipefail

echo "▶ Installation des dépendances du lab…"

# Testé avec Python 3.11 + Airflow 2.10.4 (devcontainer.json épinglé sur python:3.11-bullseye).
AIRFLOW_VERSION=2.10.4
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINTS="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install --upgrade pip

# Airflow a besoin d'un fichier de contraintes pour une install reproductible.
# Fallback : si l'URL n'existe pas (ex. version de Python plus récente que les contraintes
# publiées par Apache), on installe sans contraintes plutôt que d'échouer tout le setup.
if curl --output /dev/null --silent --head --fail "${CONSTRAINTS}"; then
  echo "  Contraintes Airflow : ${CONSTRAINTS}"
  pip install -r requirements-airflow.txt --constraint "${CONSTRAINTS}"
else
  echo "⚠ Contraintes Airflow introuvables pour Python ${PYTHON_VERSION} — install sans contraintes."
  pip install -r requirements-airflow.txt
fi

pip install -r requirements.txt

# ── CLI duckdb ───────────────────────────────────────────────────────────────
# Les consignes du lab explorent le warehouse avec `duckdb warehouse/dev.duckdb "select …"`,
# mais le binaire CLI n'est PAS livré avec le paquet Python. On l'installe, épinglé sur la
# même version que duckdb (Python) pour éviter tout décalage de format de fichier.
DUCKDB_CLI_VERSION=1.1.3
if ! command -v duckdb >/dev/null 2>&1; then
  case "$(uname -m)" in
    x86_64)  DUCKDB_ARCH=amd64 ;;
    aarch64) DUCKDB_ARCH=arm64 ;;
    *)       DUCKDB_ARCH=amd64 ;;
  esac
  if ! command -v unzip >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y -qq unzip || true
  fi
  if curl -fsSL "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_CLI_VERSION}/duckdb_cli-linux-${DUCKDB_ARCH}.zip" -o /tmp/duckdb.zip \
     && sudo unzip -o /tmp/duckdb.zip -d /usr/local/bin >/dev/null; then
    sudo chmod +x /usr/local/bin/duckdb
    echo "  ✓ CLI duckdb ${DUCKDB_CLI_VERSION} installé ($(duckdb --version))"
  else
    echo "⚠ CLI duckdb non installé (téléchargement indisponible) — le warehouse reste lisible via Python/dbt."
  fi
fi

# ── Pré-initialisation d'Airflow ─────────────────────────────────────────────
# AIRFLOW_HOME / LOAD_EXAMPLES / DAGS_FOLDER / ENABLE_PROXY_FIX viennent de containerEnv
# (devcontainer.json). On fige un fallback ici pour le cas « setup.sh hors devcontainer ».
export AIRFLOW_HOME="${AIRFLOW_HOME:-${PWD}/airflow}"
export AIRFLOW__CORE__LOAD_EXAMPLES="${AIRFLOW__CORE__LOAD_EXAMPLES:-False}"

echo "▶ Initialisation d'Airflow (metastore + utilisateur admin)…"
airflow db migrate >/dev/null 2>&1 || airflow db init >/dev/null 2>&1 || true

# Utilisateur connu admin / admin → plus de mot de passe aléatoire à pêcher dans les logs.
# Idempotent : si l'utilisateur existe déjà (ex. ré-exécution / prebuild), on n'échoue pas.
airflow users create \
  --username admin --password admin \
  --firstname Lab --lastname User \
  --role Admin --email admin@example.com >/dev/null 2>&1 || true

echo "✅ Lab prêt. Pour démarrer Airflow : make airflow (UI sur le port 8080, login admin / admin)."
