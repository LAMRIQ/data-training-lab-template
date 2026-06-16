"""
Étape Ingestion (Extract/Load) : charge les CSV bruts dans DuckDB, schéma `raw`.
C'est le point d'entrée du pipeline — en prod ce serait une API, un bucket S3, une DB source.
"""

import sys
from pathlib import Path

import duckdb

# Sortie UTF-8 même sur une console Windows (cp1252) — pour les accents et symboles.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
WAREHOUSE = ROOT / "warehouse" / "dev.duckdb"


def main() -> None:
    WAREHOUSE.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(WAREHOUSE))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw;")

    for csv in sorted(RAW_DIR.glob("*.csv")):
        table = f"raw.{csv.stem}"
        con.execute(f"CREATE OR REPLACE TABLE {table} AS SELECT * FROM read_csv_auto(?);", [str(csv)])
        n = con.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        print(f"  ✓ {table:<20} {n} lignes")

    con.close()
    print(f"✅ Ingestion terminée → {WAREHOUSE}")


if __name__ == "__main__":
    main()
