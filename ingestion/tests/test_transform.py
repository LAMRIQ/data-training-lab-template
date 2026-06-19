"""
Tests pytest de la fonction PURE transform() — sans fichier ni réseau.
Lancer depuis la racine du lab : pytest -q ingestion/tests  (ou : make test_py)
"""

import sys
from pathlib import Path

import pandas as pd
import pytest

# rend ingestion/ingest_orders.py importable quel que soit le cwd de pytest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from ingest_orders import transform  # noqa: E402


def _df(rows):
    return pd.DataFrame(rows)


def test_normalise_status_et_ecarte_les_annulees():
    df = _df(
        [
            {"order_id": 1, "customer_id": 1, "amount_eur": 10.0, "order_date": "2024-03-01", "status": "COMPLETED"},
            {"order_id": 2, "customer_id": 1, "amount_eur": 5.0, "order_date": "2024-03-02", "status": "cancelled"},
        ]
    )
    out = transform(df)
    assert len(out) == 1
    assert out.iloc[0]["status"] == "completed"


def test_colonne_manquante_leve_une_assertion():
    df = _df([{"order_id": 1}])
    with pytest.raises(AssertionError):
        transform(df)
