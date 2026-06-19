# Makefile du lab — mêmes commandes en local (devcontainer) et en CI.
# Usage : make doctor | ingest | build | test | docs | lint | dag | airflow | ci

DBT_DIR := dbt

.PHONY: doctor ingest build test test_py docs lint dag airflow check ci all

doctor:  ## Vérifie l'outillage installé
	@python --version
	@duckdb --version || echo "duckdb CLI absent (optionnel)"
	@cd $(DBT_DIR) && dbt --version
	@airflow version || echo "airflow absent (optionnel hors devcontainer)"

ingest:  ## Charge les CSV bruts dans DuckDB (schéma raw)
	python ingestion/load_raw.py

build:  ## Construit le projet dbt (run + tests)
	cd $(DBT_DIR) && dbt build --profiles-dir .

test:  ## Exécute uniquement les tests dbt
	cd $(DBT_DIR) && dbt test --profiles-dir .

docs:  ## Génère la documentation dbt
	cd $(DBT_DIR) && dbt docs generate --profiles-dir .

lint:  ## Lint SQL (sqlfluff)
	sqlfluff lint $(DBT_DIR)/models --dialect duckdb

dag:  ## Vérifie que le DAG Airflow parse (sans exécuter Airflow)
	python -m py_compile airflow/dags/nordwind_pipeline.py

airflow:  ## Démarre Airflow (UI port 8080, login admin / admin, sans DAG d'exemple)
	bash airflow/start.sh

test_py:  ## Tests Python (pytest) des fonctions d'ingestion
	pytest -q ingestion/tests

check: lint ingest build test_py dag  ## Tout valider en une commande (gestes profonds)
	@echo "OK — make check : lint + ingestion + dbt build + tests Python + DAG"

ci: lint ingest build dag  ## Pipeline complet de validation (utilisé par la CI)
	@echo "OK — CI locale : lint + ingestion + dbt build + DAG"

all: ingest build  ## Raccourci : ingestion + build
