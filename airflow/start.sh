#!/usr/bin/env bash
# Démarre Airflow pour le lab : UNE commande, login connu (admin / admin), zéro DAG d'exemple.
# Lancé par `make airflow`. Ctrl+C arrête le webserver ET le scheduler.
set -euo pipefail

# Repère la racine du repo (le dossier parent de airflow/), quel que soit le cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Réglages clés (déjà posés par containerEnv en Codespaces ; on les fige pour un run local).
export AIRFLOW_HOME="${AIRFLOW_HOME:-$ROOT/airflow}"
export AIRFLOW__CORE__DAGS_FOLDER="${AIRFLOW__CORE__DAGS_FOLDER:-$ROOT/airflow/dags}"
export AIRFLOW__CORE__LOAD_EXAMPLES="${AIRFLOW__CORE__LOAD_EXAMPLES:-False}"
export AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX="${AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX:-True}"
# Clé stable → évite l'erreur « CSRF session token is missing » au login (Airflow #28414).
export AIRFLOW__WEBSERVER__SECRET_KEY="${AIRFLOW__WEBSERVER__SECRET_KEY:-lab-secret-key-not-for-prod}"
export DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$ROOT/dbt}"

echo "▶ Préparation d'Airflow…"
airflow db migrate >/dev/null 2>&1 || airflow db init >/dev/null 2>&1 || true
# Garantit le couple admin / admin même si le setup n'a pas eu lieu (idempotent).
airflow users create \
  --username admin --password admin \
  --firstname Lab --lastname User \
  --role Admin --email admin@example.com >/dev/null 2>&1 || true

# Scheduler en tâche de fond ; on le tue proprement quand on arrête le webserver.
# NB : pas d'`exec` sur le webserver ci-dessous, sinon le shell est remplacé et ce trap
# ne se déclencherait jamais (scheduler orphelin après Ctrl+C).
airflow scheduler >"$AIRFLOW_HOME/scheduler.log" 2>&1 &
SCHED_PID=$!
trap 'echo; echo "⏹  Arrêt d'\''Airflow…"; kill "$SCHED_PID" 2>/dev/null || true' EXIT INT TERM

cat <<'BANNER'

────────────────────────────────────────────────────────────────────
✅ Airflow démarre (laisse ce terminal ouvert).

  1. Onglet PORTS (en bas de VS Code) → ligne « 8080 » → clic sur 🌐
     « Open in Browser ». (Le webserver met ~15 s à répondre la 1re fois.)
  2. Connexion :   identifiant  admin    mot de passe  admin
  3. Un seul DAG est listé : nordwind_pipeline (aucun exemple parasite).

  Ctrl+C ici pour tout arrêter.
────────────────────────────────────────────────────────────────────

BANNER

# Webserver au premier plan (Airflow 2.x ; en Airflow 3 ce serait `airflow api-server`).
# Sans `exec` : le shell reste vivant pour que le trap arrête le scheduler au Ctrl+C.
airflow webserver --port 8080
