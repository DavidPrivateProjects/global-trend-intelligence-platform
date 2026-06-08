# Architecture Diagram

```mermaid
flowchart TD
    subgraph Source["BigQuery Public Data"]
        GT["bigquery-public-data.google_trends"]
    end

    subgraph Transform["dbt Transformation Layers"]
        B["Bronze models<br/>Latest source snapshot"]
        S["Silver models<br/>Cleansed + SCD-historized"]
        G["Gold marts<br/>Dimensions, facts, aggregates"]
    end

    subgraph Runtime["Containerized Runtime"]
        DOCKER["Docker image<br/>dbt-bigquery + project code"]
        AR["Artifact Registry<br/>dbt-runner image"]
        CR["Cloud Run Job<br/>executes dbt build"]
    end

    subgraph Deployment["Deployment and Infrastructure"]
        TF["Terraform<br/>APIs, IAM, datasets, runtime resources"]
        CB["Cloud Build<br/>build, push, update job"]
    end

    subgraph Orchestration["Orchestration"]
        AF["Airflow-compatible DAG"]
        COMP["Cloud Composer<br/>optional managed Airflow target"]
    end

    subgraph Analytics["Analytics Outputs"]
        BQ["BigQuery analytics dataset"]
        LS["Looker Studio / BI dashboards"]
    end

    GT --> B
    B --> S
    S --> G
    G --> BQ
    BQ --> LS

    DOCKER --> AR
    AR --> CR
    CR --> B

    CB --> DOCKER
    CB --> AR
    CB --> CR

    TF --> BQ
    TF --> AR
    TF --> CR
    TF --> AF

    AF --> CR
    COMP -. optional production host .-> AF
```

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