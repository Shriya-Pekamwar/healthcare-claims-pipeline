import pytest

from pipeline_core.readers import read_source


def test_reads_csv_with_header_as_strings(spark, tmp_path):
    (tmp_path / "claims.csv").write_text("CLM_ID,CLM_PMT_AMT\n1,100.50\n2,200.00\n")
    df = read_source(spark, str(tmp_path), {"path": "claims.csv", "header": True})

    assert df.count() == 2
    assert "_source_file" in df.columns
    assert dict(df.dtypes)["CLM_PMT_AMT"] == "string"  # no type inference in bronze


def test_reads_headerless_pipe_file_with_columns(spark, tmp_path):
    (tmp_path / "loans.txt").write_text("L1|CA\nL2|TX\n")
    src = {"path": "loans.txt", "header": False, "delimiter": "|", "columns": ["loan_id", "state"]}
    df = read_source(spark, str(tmp_path), src)

    assert df.columns == ["loan_id", "state", "_source_file"]
    assert df.count() == 2


def test_column_count_mismatch_raises(spark, tmp_path):
    (tmp_path / "loans.txt").write_text("L1|CA|extra\n")
    src = {"path": "loans.txt", "header": False, "delimiter": "|", "columns": ["loan_id", "state"]}
    with pytest.raises(ValueError, match="columns"):
        read_source(spark, str(tmp_path), src)