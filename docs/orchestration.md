# Orchestration

## Overview

The orchestration layer is implemented as an Airflow DAG that triggers the dbt Cloud Run Job responsible for building the BigQuery models.

The project uses this pattern:

```text
Airflow DAG
    -> Cloud Run Job
        -> Dockerized dbt runtime
            -> BigQuery bronze, silver, and gold models
```

This keeps responsibilities clearly separated:

- Airflow coordinates the workflow.
- Cloud Run Jobs execute the containerized dbt runtime.
- dbt owns transformation logic, tests, documentation, and lineage.
- BigQuery stores source snapshots, historized silver models, and dashboard-ready gold marts.

## Why Airflow

Airflow is used because it is a standard orchestration tool for data platforms. It provides:

- DAG-based dependency management
- scheduling
- retry handling
- task-level observability
- clear operational ownership
- compatibility with managed services such as Cloud Composer

In this project, Airflow does not transform data directly. It only orchestrates the execution of the Cloud Run Job and validates expected BigQuery outputs.

## DAG structure

The DAG is defined in:

```text
airflow/dags/trend_intelligence_dbt_job.py
```

The intended workflow is:

```text
start
  -> check_gold_dataset
  -> run_dbt_cloud_run_job
  -> wait_for_dbt_cloud_run_job
  -> validate_gold_outputs
  -> end
```

## Task responsibilities

### `check_gold_dataset`

Runs a lightweight BigQuery metadata query against `INFORMATION_SCHEMA`.

Purpose:

- confirms BigQuery is reachable
- checks whether expected gold tables already exist
- provides a simple pre-flight validation task

### `run_dbt_cloud_run_job`

Triggers the Cloud Run Job:

```text
trend-intelligence-dbt-job
```

The job runs the Dockerized dbt project.

### `wait_for_dbt_cloud_run_job`

Waits for the Cloud Run Job execution to complete.

Depending on the Airflow Google provider version, this may be simplified if the Cloud Run operator already waits for completion.

### `validate_gold_outputs`

Runs a BigQuery metadata query to confirm that expected gold outputs exist after the dbt run.

Expected gold models include:

- `dim_geo_market`
- `dim_search_term`
- `fact_trend_rank_history`
- `fact_rising_term_momentum`
- `agg_market_trend_summary`
- `agg_search_term_performance`

## Cloud Composer compatibility

The DAG is written to be compatible with Cloud Composer, Google Cloud's managed Airflow service.

Composer is not provisioned by default in this project because it can create ongoing cost. Instead, the repository includes:

- an Airflow-compatible DAG
- Terraform-managed service accounts for orchestration
- IAM foundations for invoking Cloud Run Jobs
- documentation for how the DAG would be deployed to Composer

This keeps the portfolio project cost-aware while still demonstrating production orchestration design.

## Required permissions

The Airflow or Composer service account needs permissions to:

- invoke the Cloud Run Job
- run BigQuery metadata queries
- view execution logs

Recommended roles:

```text
roles/run.invoker
roles/bigquery.jobUser
roles/bigquery.dataViewer
roles/logging.viewer
```

In the current Terraform setup, the Airflow service account is provisioned as:

```text
airflow-runner-sa
```

## Operational behavior

A production schedule could run daily after the Google Trends public dataset refresh is expected to be available.

The Cloud Run Job runs dbt using environment variables configured through Terraform, including:

- `DBT_BIGQUERY_PROJECT`
- `DBT_BIGQUERY_DATASET`
- `DBT_BIGQUERY_LOCATION`
- `DBT_MAXIMUM_BYTES_BILLED`
- `DBT_DEV_COUNTRY_CODES`
- `DBT_DEV_US_MARKET_IDS`

For development, the optional country and market filters reduce downstream BigQuery volume and cost.

## Why not put dbt directly in Airflow?

Running dbt inside Airflow workers would couple orchestration and transformation runtime dependencies.

This project uses Cloud Run Jobs instead because they provide:

- isolated dbt runtime
- reproducible Docker execution
- serverless execution
- clear separation between orchestration and transformation
- a deployment artifact that can be promoted across environments

Airflow remains lightweight and focused on coordination.
