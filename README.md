# global-trend-intelligence-platform
A production-style data platform on GCP and BigQuery that transforms International Google Trends data into trusted analytics, reporting, and a measurable platform-health workflow with AI-assisted optimization.

## dbt project

This repository includes a starter dbt project configured for BigQuery.

### Project structure

- `dbt_project.yml` - dbt project configuration.
- `profiles.yml` - environment-variable driven BigQuery profile template.
- `models/example/` - starter models and tests.
- `models/staging/sources.yml` - placeholder source definition for raw Google Trends data.
- `analyses/`, `macros/`, `seeds/`, `snapshots/`, `tests/` - standard dbt project directories.

### Local setup

Install dbt with the BigQuery adapter:

```bash
python -m pip install -r requirements.txt
```

Configure the required environment variables:

```bash
cp .env.example .env
export DBT_BIGQUERY_PROJECT=your-gcp-project-id
export DBT_BIGQUERY_DATASET=dbt_dev
export DBT_BIGQUERY_LOCATION=US
```

Authenticate with Google Cloud for local OAuth-based development:

```bash
gcloud auth application-default login
```

Validate the project:

```bash
dbt deps --profiles-dir .
dbt debug --profiles-dir .
dbt build --profiles-dir .
```
