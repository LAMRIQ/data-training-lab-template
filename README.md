# data-training-lab — Template de lab

Environnement de pratique **prêt à l'emploi** pour le parcours data engineering.
Ouvre-le en un clic dans **GitHub Codespaces** : tout est pré-installé (Python, dbt + DuckDB,
Airflow, sqlfluff). Aucune config locale.

> Le warehouse est **DuckDB** (gratuit, instantané) : il enseigne 95 % des concepts dbt/SQL
> que tu retrouveras sur Snowflake. Le « spécifique Snowflake » est vu en conceptuel.

## Le pipeline que tu construis

```
data/raw/*.csv ──ingestion──▶ DuckDB (raw)
                                  │
                            dbt staging (views)   ── stg_orders, stg_customers
                                  │
                            dbt marts (tables)    ── fct_sales, dim_customers
                                  │
                            Airflow orchestre le tout (DAG elt_pipeline)
                                  │
                            CI GitHub Actions : sqlfluff + dbt build + tests
```

## Démarrage rapide

```bash
# 1. Ingestion : charge les CSV bruts dans DuckDB
python ingestion/load_raw.py

# 2. Transformation : construis staging + marts
cd dbt && dbt build        # = dbt run + dbt test

# 3. Explore le résultat
duckdb warehouse/dev.duckdb "select * from fct_sales limit 10;"

# 4. Orchestration : lance Airflow et déclenche le DAG
airflow standalone         # UI sur le port 8080 (login affiché dans le terminal)
```

## Structure

| Dossier | Rôle |
|---|---|
| `data/raw/` | Fichiers sources (CSV) |
| `ingestion/` | Chargement des données brutes (étape *Extract/Load*) |
| `dbt/` | Projet dbt : `staging/` → `marts/` (étape *Transform*) |
| `airflow/dags/` | Orchestration du pipeline |
| `.github/workflows/` | CI : lint SQL + tests dbt |
| `warehouse/` | Base DuckDB (générée, git-ignorée) |

## Comment ta progression est validée

Ton exercice est « réussi » quand `dbt build` passe (les **tests dbt** sont verts) et que la
**CI GitHub Actions** est au vert sur ta Pull Request. C'est exactement le signal qu'attend
un employeur.
