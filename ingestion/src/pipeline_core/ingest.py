"""Build, check, and write bronze tables for every configured source."""

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F

from pipeline_core.config import target_table
from pipeline_core.quality import run_quality_checks
from pipeline_core.readers import read_source
from pipeline_core.transforms import add_audit_columns, add_source_year, standardize_columns

RESULT_SCHEMA = (
    "source string, target_table string, row_count long, "
    "batch_id string, status string, error string"
)


def build_bronze_df(spark: SparkSession, cfg: dict, source_name: str, batch_id: str) -> DataFrame:
    """Read and lightly prepare one source. No writes, so this is unit-testable."""
    src = cfg["sources"][source_name]
    df = read_source(spark, cfg["defaults"]["volume"], src)
    df = standardize_columns(df)
    if src.get("source_year") is not None:
        df = add_source_year(df, src["source_year"])
    return add_audit_columns(df, batch_id)


def ingest_source(spark: SparkSession, cfg: dict, source_name: str, batch_id: str) -> dict:
    src = cfg["sources"][source_name]
    table = target_table(cfg, source_name)

    df = build_bronze_df(spark, cfg, source_name, batch_id)
    row_count = run_quality_checks(df, src)

    df.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(table)

    return {
        "source": source_name,
        "target_table": table,
        "row_count": row_count,
        "batch_id": batch_id,
        "status": "success",
        "error": None,
    }


def results_to_df(spark: SparkSession, results: list[dict]) -> DataFrame:
    rows = [
        (r["source"], r["target_table"], r["row_count"], r["batch_id"], r["status"], r["error"])
        for r in results
    ]
    return spark.createDataFrame(rows, RESULT_SCHEMA)


def write_ingestion_log(spark: SparkSession, cfg: dict, results: list[dict]) -> None:
    d = cfg["defaults"]
    (
        results_to_df(spark, results)
        .withColumn("logged_at", F.current_timestamp())
        .write.mode("append")
        .saveAsTable(f"{d['catalog']}.{d['bronze_schema']}.ingestion_log")
    )


def ingest_all(spark: SparkSession, cfg: dict, batch_id: str) -> list[dict]:
    """Ingest every source, log every outcome, then fail the run if anything failed."""
    results = []
    for name in cfg["sources"]:
        try:
            results.append(ingest_source(spark, cfg, name, batch_id))
        except Exception as exc:
            results.append(
                {
                    "source": name,
                    "target_table": target_table(cfg, name),
                    "row_count": None,
                    "batch_id": batch_id,
                    "status": "failed",
                    "error": str(exc)[:1000],
                }
            )

    write_ingestion_log(spark, cfg, results)

    failed = [r["source"] for r in results if r["status"] == "failed"]
    if failed:
        raise RuntimeError(f"Ingestion failed for: {failed}. See bronze.ingestion_log.")
    return results