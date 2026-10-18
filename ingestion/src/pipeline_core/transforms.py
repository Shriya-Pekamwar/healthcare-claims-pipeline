"""Pure, reusable DataFrame transforms for the bronze layer."""

from pyspark.sql import DataFrame
from pyspark.sql import functions as F


def standardize_columns(df: DataFrame) -> DataFrame:
    """Trim, lowercase, and snake_case all column names."""
    return df.toDF(*[c.strip().lower().replace(" ", "_") for c in df.columns])


def add_audit_columns(df: DataFrame, batch_id: str) -> DataFrame:
    """Add lineage metadata to every row."""
    return df.withColumn("_ingested_at", F.current_timestamp()).withColumn(
        "_batch_id", F.lit(batch_id)
    )


def add_source_year(df: DataFrame, year: int) -> DataFrame:
    """Tag rows from yearly files with the year they came from."""
    return df.withColumn("source_year", F.lit(year))