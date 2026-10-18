"""Load and validate the YAML source config."""

from pathlib import Path

import yaml

REQUIRED_DEFAULT_KEYS = {"catalog", "bronze_schema", "volume"}
REQUIRED_SOURCE_KEYS = {"path", "load_mode", "required_columns", "min_rows"}
VALID_LOAD_MODES = {"overwrite"}


class ConfigError(Exception):
    """Raised when the source config is malformed."""


def load_config(path: str | Path) -> dict:
    with open(path) as f:
        cfg = yaml.safe_load(f)
    validate_config(cfg)
    return cfg


def validate_config(cfg: dict) -> None:
    if not isinstance(cfg, dict) or "defaults" not in cfg or "sources" not in cfg:
        raise ConfigError("Config must have top-level 'defaults' and 'sources' sections")

    missing_defaults = REQUIRED_DEFAULT_KEYS - set(cfg["defaults"])
    if missing_defaults:
        raise ConfigError(f"defaults is missing keys: {sorted(missing_defaults)}")

    if not cfg["sources"]:
        raise ConfigError("At least one source must be defined")

    for name, src in cfg["sources"].items():
        missing = REQUIRED_SOURCE_KEYS - set(src)
        if missing:
            raise ConfigError(f"Source '{name}' is missing keys: {sorted(missing)}")
        if src["load_mode"] not in VALID_LOAD_MODES:
            raise ConfigError(
                f"Source '{name}' has invalid load_mode '{src['load_mode']}'. "
                f"Valid modes: {sorted(VALID_LOAD_MODES)}"
            )


def target_table(cfg: dict, source_name: str) -> str:
    d = cfg["defaults"]
    return f"{d['catalog']}.{d['bronze_schema']}.{source_name}"