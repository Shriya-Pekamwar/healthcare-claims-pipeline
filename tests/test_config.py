import copy
from pathlib import Path

import pytest
import yaml

from pipeline_core.config import ConfigError, load_config, target_table

REPO_ROOT = Path(__file__).resolve().parents[1]

VALID = {
    "defaults": {"catalog": "workspace", "bronze_schema": "bronze", "volume": "/tmp/data"},
    "sources": {
        "claims": {
            "path": "claims.csv",
            "load_mode": "overwrite",
            "required_columns": ["clm_id"],
            "min_rows": 1,
        }
    },
}


def write_yaml(tmp_path, data):
    p = tmp_path / "sources.yml"
    p.write_text(yaml.safe_dump(data))
    return p


def test_repo_config_is_valid():
    """Guards the real config file: CI fails if someone breaks it."""
    cfg = load_config(REPO_ROOT / "config" / "sources.yml")
    assert len(cfg["sources"]) > 0


def test_valid_config_loads(tmp_path):
    cfg = load_config(write_yaml(tmp_path, VALID))
    assert target_table(cfg, "claims") == "workspace.bronze.claims"


def test_missing_source_key_raises(tmp_path):
    bad = copy.deepcopy(VALID)
    del bad["sources"]["claims"]["min_rows"]
    with pytest.raises(ConfigError, match="min_rows"):
        load_config(write_yaml(tmp_path, bad))


def test_invalid_load_mode_raises(tmp_path):
    bad = copy.deepcopy(VALID)
    bad["sources"]["claims"]["load_mode"] = "upsert"
    with pytest.raises(ConfigError, match="invalid load_mode"):
        load_config(write_yaml(tmp_path, bad))


def test_missing_defaults_raises(tmp_path):
    bad = copy.deepcopy(VALID)
    del bad["defaults"]["volume"]
    with pytest.raises(ConfigError, match="volume"):
        load_config(write_yaml(tmp_path, bad))