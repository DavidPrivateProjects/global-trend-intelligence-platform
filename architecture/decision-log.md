# Architecture Decision Log

This document captures the main architecture decisions behind the Global Trend Intelligence Platform and the tradeoffs considered while building it.

## ADR-001: Use BigQuery public Google Trends as the native source

### Decision

Use `bigquery-public-data.google_trends` tables directly as the raw source layer.

### Rationale

The project is intended to demonstrate analytics engineering and cloud data platform design, not file ingestion mechanics. Using native BigQuery public datasets keeps the pipeline focused on:

- warehouse-native transformation
- cost-aware querying
- data quality testing
- historized modeling
- cloud execution and orchestration

### Alternatives considered

- Cloud Storage CSV ingestion
- synthetic local files
- external APIs

### Tradeoff

Using public BigQuery data avoids ingestion boilerplate, but source scan cost must be controlled carefully. The project addresses this with snapshot filters, explicit column selection, development filters, and a maximum bytes billed guardrail.

## ADR-002: Use dbt for transformation, tests, and lineage

### Decision

Use dbt as the transformation framework for bronze, silver, and gold models.

### Rationale

dbt is a strong fit because the project is SQL-heavy and targets BigQuery. It provides:

- modular SQL models
- model dependencies through `ref()` and `source()`
- generic and custom data tests
- documentation and lineage generation
- environment-driven configuration

### Alternatives considered

- handwritten SQL scripts
- Apache Beam
- PySpark
- stored procedures

### Tradeoff

dbt is not an orchestration engine and does not replace infrastructure. The project keeps orchestration in Airflow and execution in Cloud Run Jobs.

## ADR-003: Use a bronze/silver/gold modeling pattern

### Decision

Organize dbt models into bronze, silver, and gold layers.

### Rationale

The medallion-style structure makes the pipeline easier to explain and maintain:

- bronze captures source snapshots
- silver applies cleansing, deduplication, and historization
- gold provides dimensional and aggregated marts for dashboards

### Alternatives considered

- single-layer marts directly from sources
- staging/marts only
- one wide reporting table

### Tradeoff

More layers add more models, but each layer has a clear purpose and supports better testing, lineage, and debugging.

## ADR-004: Historize in silver with SCD-style fields

### Decision

Implement SCD-style historization in the silver layer.

### Rationale

Google Trends snapshots can change over time. The project needs to preserve historical rank and momentum changes rather than only storing the latest state.

Silver models create:

- `trend_natural_key`
- `trend_history_key`
- `scd2_hash`
- `valid_from_refresh_date`
- `valid_to_refresh_date`
- `is_current`

### SCD interpretation

- SCD0 fields define stable natural grain, such as week, geography, and normalized term.
- SCD1 fields are descriptive corrections, such as display names.
- SCD2 fields are analytical values whose changes should create history, such as rank, score, and percent gain.

### Tradeoff

SCD logic is more complex than append-only snapshots. To reduce risk, the project adds reusable macros and explicit SCD integrity tests.

## ADR-005: Build dashboard-ready gold marts

### Decision

Create gold dimensions, fact tables, and aggregate tables instead of only exposing silver models.

### Rationale

Dashboards should not have to understand source-specific schemas. Gold models provide:

- `dim_geo_market`
- `dim_search_term`
- `fact_trend_rank_history`
- `fact_rising_term_momentum`
- `agg_market_trend_summary`
- `agg_search_term_performance`

These models make the data easier to consume in BigQuery, Looker Studio, or other BI tools.

### Tradeoff

Gold tables can be large if fully materialized. Development filters and runtime dataset overrides keep cloud test runs cost-aware.

## ADR-006: Use Docker for the dbt runtime

### Decision

Package dbt and the project code into a Docker image.

### Rationale

Docker gives the project a reproducible runtime across local development, Cloud Build, and Cloud Run Jobs.

The image contains:

- Python
- dbt BigQuery adapter
- dbt project files
- entrypoint script

### Alternatives considered

- installing dbt directly on each runtime
- running dbt only from a developer laptop
- packaging a Python virtual environment

### Tradeoff

Docker adds image build complexity, but it creates a production-style deployment artifact and removes local environment drift.

## ADR-007: Use Cloud Run Jobs for dbt execution

### Decision

Use Cloud Run Jobs to execute the dbt container.

### Rationale

dbt is a batch workload. Cloud Run Jobs fit this better than a long-running Cloud Run service because a job:

- starts
- runs `dbt build`
- exits with success or failure

This gives clear operational semantics and avoids maintaining a web API solely to trigger dbt.

### Alternatives considered

- Cloud Run service with Flask/FastAPI
- running dbt directly in Airflow workers
- scheduled BigQuery queries
- local-only dbt execution

### Tradeoff

Cloud Run Jobs require container deployment and IAM setup, but they provide a clean serverless execution boundary.

## ADR-008: Use Airflow-compatible orchestration, keep Composer optional

### Decision

Implement the orchestration pattern as an Airflow-compatible DAG, while keeping Cloud Composer optional.

### Rationale

Airflow demonstrates production orchestration concepts:

- scheduling
- dependencies
- retries
- task observability
- separation of orchestration and transformation

Cloud Composer is the managed GCP target for Airflow, but it can create ongoing cost.

### Alternatives considered

- Cloud Scheduler directly invoking Cloud Run
- Workflows
- Composer provisioned by default
- no orchestration layer

### Tradeoff

The repository documents a Composer-compatible path without forcing Composer costs during portfolio development.

## ADR-009: Use Terraform for cloud infrastructure

### Decision

Use Terraform to define GCP infrastructure.

### Rationale

Terraform makes the cloud setup reproducible and reviewable. It also demonstrates infrastructure engineering beyond local dbt development.

Terraform covers:

- required APIs
- BigQuery dataset
- service accounts
- IAM bindings
- Artifact Registry
- Cloud Run Job

### Alternatives considered

- manual console setup
- shell scripts with `gcloud`
- relying only on local dbt execution

### Tradeoff

Terraform introduces state management and bootstrapping concerns. The deployment documentation explains the first image bootstrap and later Cloud Build deployment flow.

## ADR-010: Keep cost controls visible and configurable

### Decision

Add explicit cost controls across dbt and Cloud Run.

### Rationale

The source tables can scan multiple GiB per run. The project should be safe to develop and demo without uncontrolled spend.

Controls include:

- BigQuery maximum bytes billed
- single `refresh_date` snapshots in bronze
- optional explicit source refresh dates
- optional country code filters
- optional US market ID filters
- separate runtime dataset for filtered cloud tests

### Tradeoff

Development filters can produce smaller outputs than full production runs. This is acceptable because the filters are environment-driven and can be disabled for full builds.

## ADR-011: Use BigQuery and Looker Studio as the dashboard path

### Decision

Expose dashboard-ready gold tables in BigQuery and target Looker Studio for visualization.

### Rationale

Looker Studio integrates directly with BigQuery and is lightweight for portfolio demos. Keeping dashboard data in gold marts lets the project demonstrate BI readiness without adding another application layer.

### Alternatives considered

- custom dashboard app
- notebooks
- exported CSVs

### Tradeoff

Looker Studio dashboard definitions are not as code-native as dbt models. The repository will document dashboard queries and screenshots to make the presentation reproducible.
