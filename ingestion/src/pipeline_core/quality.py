"""Bronze-level data quality checks. These fail the ingestion run before bad data lands."""

from pyspark.sql import DataFrame
from pyspark.sql import functions as F


class DataQualityError(Exception):
    """Raised when a bronze data quality check fails."""


def check_required_columns(df: DataFrame, required: list[str]) -> None:
    missing = set(required) - set(df.columns)
    if missing:
        raise DataQualityError(f"Missing required columns: {sorted(missing)}")


def check_keys_not_null(df: DataFrame, key_columns: list[str]) -> None:
    for col in key_columns:
        bad = df.filter(F.col(col).isNull() | (F.trim(F.col(col)) == "")).count()
        if bad > 0:
            raise DataQualityError(f"{bad} rows have a null or blank '{col}'")


def check_min_rows(df: DataFrame, min_rows: int) -> int:
    n = df.count()
    if n < min_rows:
        raise DataQualityError(f"Expected at least {min_rows} rows, got {n}")
    return n


def run_quality_checks(df: DataFrame, src: dict) -> int:
    """Run all configured checks for one source. Returns the row count."""
    check_required_columns(df, src["required_columns"])
    check_keys_not_null(df, src.get("key_columns", []))
    return check_min_rows(df, src["min_rows"])