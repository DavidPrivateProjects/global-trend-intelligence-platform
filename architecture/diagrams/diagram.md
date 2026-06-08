# Architecture Diagram

The architecture is split into focused diagrams so each view remains readable in GitHub and documentation previews.

## 1. Data and modeling flow

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontSize": "18px", "fontFamily": "Arial"}}}%%
flowchart LR
    public_bq["BigQuery Public Data<br/>Google Trends"]
    bronze["Bronze<br/>Daily snapshots"]
    silver["Silver<br/>Cleaned SCD history"]
    gold["Gold<br/>Facts + dimensions"]
    dashboards["Dashboards<br/>Looker Studio / BI"]

    public_bq --> bronze
    bronze --> silver
    silver --> gold
    gold --> dashboards
```

## 2. Runtime and deployment flow

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontSize": "18px", "fontFamily": "Arial"}}}%%
flowchart LR
    code["cloud_run_dbt/<br/>dbt project + Dockerfile"]
    build["Cloud Build<br/>build image"]
    registry["Artifact Registry<br/>dbt-runner:latest"]
    job["Cloud Run Job<br/>dbt build"]
    bq["BigQuery<br/>bronze / silver / gold"]

    code --> build
    build --> registry
    registry --> job
    job --> bq
```

## 3. Orchestration and infrastructure flow

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontSize": "18px", "fontFamily": "Arial"}}}%%
flowchart LR
    terraform["Terraform<br/>APIs + IAM + runtime"]
    airflow["Airflow DAG<br/>orchestration"]
    composer["Cloud Composer<br/>optional host"]
    job["Cloud Run Job"]
    logs["Cloud Logging<br/>run observability"]
    bq["BigQuery<br/>metadata validation"]

    terraform -. provisions .-> job
    terraform -. provisions .-> bq
    terraform -. provisions .-> airflow

    composer -. optional .-> airflow
    airflow --> job
    airflow --> bq
    job --> logs
```

## Data flow

1. dbt reads Google Trends public tables from BigQuery.
2. Bronze models persist one cost-aware source snapshot.
3. Silver models cleanse, deduplicate, and historize trend records.
4. Gold marts expose dimensional, fact, and aggregate tables for dashboards.

## Control flow

1. Airflow triggers the Cloud Run Job.
2. Cloud Run starts the dbt container.
3. The dbt container runs `dbt build`.
4. Airflow validates expected BigQuery outputs.

## Deployment flow

1. Terraform provisions GCP APIs, IAM, BigQuery, Artifact Registry, and Cloud Run Job resources.
2. Cloud Build builds the dbt Docker image.
3. Cloud Build pushes the image to Artifact Registry.
4. Cloud Build updates the Cloud Run Job to use the latest image.

## Layer responsibilities

| Layer | Responsibility |
| --- | --- |
| BigQuery public data | Native source tables for Google Trends signals. |
| Bronze | Cost-aware daily source snapshots with explicit column selection and optional development filters. |
| Silver | Cleansed, deduplicated, SCD-style historized trend records. |
| Gold | Dashboard-ready dimensions, facts, and aggregate tables. |
| Docker | Reproducible dbt runtime package. |
| Cloud Build | Builds and deploys the dbt container image. |
| Artifact Registry | Stores the deployable dbt image. |
| Cloud Run Job | Executes `dbt build` as a serverless batch workload. |
| Airflow | Coordinates execution and validation without owning transformation logic. |
| Terraform | Provisions repeatable GCP infrastructure and IAM. |