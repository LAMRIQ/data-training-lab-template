# data-training-lab — Template de lab

Environnement de pratique **prêt à l'emploi** pour le parcours data engineering.
Ouvre-le en un clic dans **GitHub Codespaces** : tout est pré-installé (Python, dbt + DuckDB,
Airflow, sqlfluff). Aucune config locale.

> Le warehouse est **DuckDB** (gratuit, instantané) : il enseigne 95 % des concepts dbt/SQL
> que tu retrouveras sur Snowflake. Le « spécifique Snowflake » est vu en conceptuel.

## Le pipeline que tu construis

```
data/raw/*.csv ──ingestion──▶ DuckDB (raw)            ── orders, customers, products
                                  │
                       dbt staging (views)            ── stg_orders, stg_customers, stg_products
                                  │
                       dbt intermediate (views)       ── int_orders_enriched, int_customer_orders
                                  │
                       dbt marts (tables)             ── fct_daily_sales, dim_products, fct_customer_metrics
                                  │
                       Airflow orchestre le tout (DAG nordwind_pipeline)
                                  │
                       CI GitHub Actions : sqlfluff + dbt build + tests + parsing du DAG
```

Les marts répondent aux 3 questions métier du capstone : **CA quotidien & tendance**
(`fct_daily_sales`), **top produits / marge** (`dim_products`), **rétention & valeur client**
(`fct_customer_metrics`).

## Démarrage rapide

Les mêmes cibles `make` servent en local et en CI :

```bash
make ingest    # 1. charge les CSV bruts dans DuckDB (schéma raw)
make build     # 2. construit staging → intermediate → marts (= dbt run + dbt test)
make ci        # tout valider d'un coup : lint SQL + ingest + build + parsing du DAG
make airflow   # 3. orchestration : démarre l'UI Airflow (port 8080, login admin / admin)
```

Sans `make` (équivalents directs) :

```bash
python ingestion/load_raw.py                       # ingestion
cd dbt && dbt build --profiles-dir .               # transformation + tests
duckdb warehouse/dev.duckdb "select * from fct_daily_sales;"   # explorer un mart
bash airflow/start.sh                              # orchestration : UI sur le port 8080
```

## Lancer Airflow (orchestration)

```bash
make airflow
```

1. Laisse ce terminal ouvert (il fait tourner le scheduler + le webserver).
2. Ouvre l'onglet **PORTS** (en bas de VS Code), ligne **8080**, clique sur l'icône 🌐
   **« Open in Browser »**. Le webserver met ~15 s à répondre au premier démarrage.
3. Connecte-toi : identifiant **`admin`**, mot de passe **`admin`**.
4. Un **seul** DAG est listé — `nordwind_pipeline` (les exemples Airflow sont désactivés
   pour ne pas noyer le DAG du capstone). Active-le (toggle), déclenche-le (▶), puis lis
   le **Grid** et le **Graph**.

> Connexion impossible / page qui boucle ? C'est déjà géré : le devcontainer active
> `ENABLE_PROXY_FIX` (indispensable derrière le proxy HTTPS de Codespaces). `Ctrl+C` dans
> le terminal arrête proprement Airflow.

## Structure

| Dossier | Rôle |
|---|---|
| `data/raw/` | Fichiers sources (CSV) : commandes, clients, produits |
| `ingestion/` | Chargement des données brutes (étape *Extract/Load*) |
| `dbt/` | Projet dbt : `staging/` → `intermediate/` → `marts/` (étape *Transform*) |
| `airflow/dags/` | Orchestration du pipeline |
| `.github/workflows/` | CI : lint SQL + tests dbt + parsing du DAG |
| `warehouse/` | Base DuckDB (générée, git-ignorée) |

## Comment ta progression est validée

Ton exercice est « réussi » quand `make ci` passe en local **et** que la **CI GitHub Actions**
est au vert sur ta Pull Request (les **tests dbt** sont verts). C'est exactement le signal
qu'attend un employeur.
