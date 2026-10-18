"""Read delimited source files into Spark DataFrames."""

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F


def read_source(spark: SparkSession, base_path: str, src: dict) -> DataFrame:
    """Read one delimited file (or glob) as all-string columns, plus its source file path.

    If the file has no header row, pass `columns` in the source config to name the fields.
    """
    full_path = f"{base_path.rstrip('/')}/{src['path']}"

    df = (
        spark.read.option("header", src.get("header", True))
        .option("delimiter", src.get("delimiter", ","))
        .option("inferSchema", False)
        .csv(full_path)
        .select("*", F.col("_metadata.file_path").alias("_source_file"))
    )

    columns = src.get("columns")
    if columns:
        expected = len(columns) + 1  # +1 for _source_file
        if len(df.columns) != expected:
            raise ValueError(
                f"Config lists {len(columns)} columns but file has {len(df.columns) - 1}"
            )
        df = df.toDF(*columns, "_source_file")

    return df