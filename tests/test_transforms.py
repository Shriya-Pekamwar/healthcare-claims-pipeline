from pipeline_core.transforms import add_audit_columns, add_source_year, standardize_columns


def test_standardize_columns(spark):
    df = spark.createDataFrame([(1, 2)], [" CLM_ID ", "Bene Name"])
    assert standardize_columns(df).columns == ["clm_id", "bene_name"]


def test_add_audit_columns(spark):
    df = add_audit_columns(spark.createDataFrame([(1,)], ["a"]), "batch-123")
    assert {"_ingested_at", "_batch_id"} <= set(df.columns)
    assert df.first()["_batch_id"] == "batch-123"


def test_add_source_year(spark):
    df = add_source_year(spark.createDataFrame([(1,)], ["a"]), 2009)
    assert df.first()["source_year"] == 2009