from pipeline_core.ingest import build_bronze_df
from pipeline_core.quality import run_quality_checks


def test_build_bronze_df_end_to_end(spark, tmp_path):
    (tmp_path / "ip.csv").write_text("CLM_ID,DESYNPUF_ID\n1,A\n2,B\n")
    cfg = {
        "defaults": {"catalog": "workspace", "bronze_schema": "bronze", "volume": str(tmp_path)},
        "sources": {
            "inpatient_claims": {
                "path": "ip.csv",
                "header": True,
                "load_mode": "overwrite",
                "source_year": 2008,
                "required_columns": ["clm_id", "desynpuf_id"],
                "key_columns": ["clm_id"],
                "min_rows": 2,
            }
        },
    }

    df = build_bronze_df(spark, cfg, "inpatient_claims", "batch-1")

    expected = {"clm_id", "desynpuf_id", "source_year", "_batch_id", "_ingested_at", "_source_file"}
    assert expected <= set(df.columns)
    assert run_quality_checks(df, cfg["sources"]["inpatient_claims"]) == 2