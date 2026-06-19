"""
Squelette d'ingestion Python — fonctions PURES (extract / transform / load_raw) + main().

C'est le pendant du module 03 (Python) : on lit une source, on la nettoie/valide, et on
écrit le brut de façon IDEMPOTENTE (une partition par date, réécrite à chaque run).
Les fonctions sont pures (entrée -> sortie, sans effet de bord caché) : on les TESTE avec
pytest (ingestion/tests/) et on les réutilise telles quelles dans un @task Airflow.

Lancer :  python ingestion/ingest_orders.py
Tester :  make test_py   (ou : pytest -q ingestion/tests)
"""

from pathlib import Path

import pandas as pd

# Colonnes minimales attendues dans la source (garde-fou de schéma).
ATTENDU = {"order_id", "customer_id", "amount_eur", "order_date", "status"}


def extract(path: str) -> pd.DataFrame:
    """Lit la source en DataFrame. Ajuste sep/encoding selon ta source réelle."""
    return pd.read_csv(path)


def transform(df: pd.DataFrame) -> pd.DataFrame:
    """Valide le schéma (fail fast), normalise, applique une règle métier d'exemple."""
    manquantes = ATTENDU - set(df.columns)
    assert not manquantes, f"colonnes manquantes : {manquantes}"

    out = df.copy()
    out["status"] = out["status"].str.lower()
    out["amount_eur"] = out["amount_eur"].astype(float)
    assert out["amount_eur"].notna().all(), "des montants sont NULL"

    # règle métier d'exemple : on ne charge pas les commandes annulées
    return out[out["status"] != "cancelled"].reset_index(drop=True)


def load_raw(df: pd.DataFrame, ds: str, base: str = "data/raw") -> None:
    """Écrit une partition par date. Réécrire la partition du jour = idempotent."""
    part = Path(base) / f"dt={ds}"
    part.mkdir(parents=True, exist_ok=True)
    df.to_parquet(part / "orders.parquet")  # écrase -> relancer ne duplique pas


def main() -> None:
    df = transform(extract("data/raw/orders.csv"))
    load_raw(df, ds="2024-03-10")
    print(f"{len(df)} lignes chargées dans data/raw/dt=2024-03-10/orders.parquet")


if __name__ == "__main__":
    main()
