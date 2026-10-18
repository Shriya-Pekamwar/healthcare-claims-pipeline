import pytest

from pipeline_core.quality import (
    DataQualityError,
    check_keys_not_null,
    check_min_rows,
    check_required_columns,
    run_quality_checks,
)


def test_required_columns_pass(spark):
    df = spark.createDataFrame([("1",)], ["clm_id"])
    check_required_columns(df, ["clm_id"])  # should not raise


def test_required_columns_missing_raises(spark):
    df = spark.createDataFrame([("1",)], ["other"])
    with pytest.raises(DataQualityError, match="clm_id"):
        check_required_columns(df, ["clm_id"])


def test_null_key_raises(spark):
    df = spark.createDataFrame([("1",), (None,)], "clm_id string")
    with pytest.raises(DataQualityError, match="clm_id"):
        check_keys_not_null(df, ["clm_id"])


def test_blank_key_raises(spark):
    df = spark.createDataFrame([("1",), ("   ",)], "clm_id string")
    with pytest.raises(DataQualityError):
        check_keys_not_null(df, ["clm_id"])


def test_min_rows(spark):
    df = spark.createDataFrame([("1",), ("2",)], ["clm_id"])
    assert check_min_rows(df, 2) == 2
    with pytest.raises(DataQualityError):
        check_min_rows(df, 3)


def test_run_quality_checks_returns_count(spark):
    df = spark.createDataFrame([("1",), ("2",)], ["clm_id"])
    src = {"required_columns": ["clm_id"], "key_columns": ["clm_id"], "min_rows": 1}
    assert run_quality_checks(df, src) == 2
