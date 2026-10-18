# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "6"
# ///
# MAGIC %md
# MAGIC # Bronze ingestion
# MAGIC Reads every source listed in `config/sources.yml`, runs bronze quality checks,
# MAGIC and writes raw Delta tables to `workspace.bronze`. Every run is logged to
# MAGIC `workspace.bronze.ingestion_log`.

# COMMAND ----------

import os
import sys
import uuid

# Make the pipeline_core package importable (notebook runs from ingestion/notebooks/)
sys.path.insert(0, os.path.abspath("../src"))

from pipeline_core.config import load_config
from pipeline_core.ingest import ingest_all, results_to_df

# COMMAND ----------

dbutils.widgets.text("config_path", "../../config/sources.yml")
config_path = os.path.abspath(dbutils.widgets.get("config_path"))

cfg = load_config(config_path)
batch_id = str(uuid.uuid4())
print(f"Batch {batch_id}: ingesting {len(cfg['sources'])} sources from {config_path}")

# COMMAND ----------

results = ingest_all(spark, cfg, batch_id)
display(results_to_df(spark, results))