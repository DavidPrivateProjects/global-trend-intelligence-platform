# Deployment Workflow

## Overview

The project deployment flow connects Terraform, Docker, Cloud Build, Artifact Registry, Cloud Run Jobs, and BigQuery.

```text
Terraform
    -> provisions GCP infrastructure

Docker
    -> packages the dbt runtime

Cloud Build
    -> builds and pushes the Docker image

Artifact Registry
    -> stores the dbt image

Cloud Run Job
    -> executes dbt build

BigQuery
    -> stores bronze, silver, and gold models
```

## Infrastructure provisioning

Terraform provisions the core cloud resources:

- required Google Cloud APIs
- BigQuery dataset
- Artifact Registry repository
- Cloud Run Job
- service accounts
- IAM role bindings

Terraform files are located in:

```text
terraform/
```

Important files:

```text
terraform/apis.tf
terraform/bigquery.tf
terraform/artifact_registry.tf
terraform/cloud_run_job.tf
terraform/service_accounts.tf
terraform/variables.tf
terraform/outputs.tf
```

## Terraform validation

From the Terraform directory:

```bash
cd terraform
terraform fmt
terraform init
terraform validate
terraform plan
```

Apply only when ready to create or update cloud resources:

```bash
terraform apply
```

## BigQuery dataset

The default dbt dataset is:

```text
trend_intelligence_dev
```

For cost-controlled Cloud Run testing, the runtime dataset can be overridden with:

```hcl
dbt_runtime_dataset_id = "trend_intelligence_dev_filtered"
```

This allows the Terraform-managed default dataset to remain stable while Cloud Run can target a filtered development dataset.

## Docker image

The dbt runtime is packaged as a Docker image from:

```text
cloud_run_dbt/
```

The image contains:

- Python runtime
- dbt BigQuery adapter
- dbt project files
- entrypoint script

Local validation:

```bash
cd cloud_run_dbt
docker compose run --rm dbt dbt debug
docker compose run --rm dbt dbt build
```

## First image bootstrap

Cloud Run Jobs require an image to exist before the job can be created successfully.

For the first bootstrap image:

```bash
cd cloud_run_dbt
gcloud builds submit \
  --tag europe-west6-docker.pkg.dev/centering-crow-496515-u6/trend-intelligence-dbt/dbt-runner:latest .
```

After the image exists, Terraform can create or update the Cloud Run Job.

## Cloud Build deployment

Cloud Build configuration is located at:

```text
cloud_run_dbt/cloudbuild.yaml
```

The Cloud Build pipeline:

1. builds the dbt Docker image
2. pushes the image to Artifact Registry
3. updates the Cloud Run Job to use the latest image

Run from `cloud_run_dbt/`:

```bash
gcloud builds submit --config cloudbuild.yaml .
```

## Artifact Registry

Docker images are stored in Artifact Registry:

```text
europe-west6-docker.pkg.dev/centering-crow-496515-u6/trend-intelligence-dbt/dbt-runner:latest
```

This image URI is also exposed as a Terraform output:

```bash
terraform output dbt_image_uri
```

## Cloud Run Job execution

The Cloud Run Job is:

```text
trend-intelligence-dbt-job
```

Execute it manually:

```bash
gcloud run jobs execute trend-intelligence-dbt-job \
  --region europe-west6 \
  --wait
```

The job runs the container entrypoint:

```bash
dbt build
```

## Logs

View recent Cloud Run Job logs:

```bash
gcloud logging read \
  "resource.type=cloud_run_job AND resource.labels.job_name=trend-intelligence-dbt-job" \
  --limit=100 \
  --format="table(timestamp,textPayload)"
```

View model creation lines:

```bash
gcloud logging read \
  "resource.type=cloud_run_job AND resource.labels.job_name=trend-intelligence-dbt-job AND textPayload:CREATE TABLE" \
  --limit=200 \
  --format="table(timestamp,textPayload)"
```

## Cost controls

The project includes several cost controls.

### BigQuery bytes billed cap

Configured in `profiles.yml`:

```yaml
maximum_bytes_billed: "{{ env_var('DBT_MAXIMUM_BYTES_BILLED', 20000000000) | int }}"
```

### Bronze snapshot filters

Bronze models load a single source snapshot by `refresh_date`.

Optional explicit refresh-date variables can be used to avoid repeatedly computing the latest snapshot:

```text
DBT_INTERNATIONAL_TOP_TERMS_REFRESH_DATE
DBT_INTERNATIONAL_TOP_RISING_TERMS_REFRESH_DATE
DBT_TOP_TERMS_REFRESH_DATE
DBT_TOP_RISING_TERMS_REFRESH_DATE
```

### Development filters

Cloud Run can restrict development runs to selected countries and US market IDs:

```text
DBT_DEV_COUNTRY_CODES
DBT_DEV_US_MARKET_IDS
```

Example:

```hcl
dbt_dev_country_codes = "CH,DE,AT"
dbt_dev_us_market_ids = "500"
```

These filters reduce downstream row counts and gold model processing volume.

## Deployment sequence

Recommended sequence:

```text
1. terraform init / validate / plan
2. terraform apply
3. bootstrap initial Docker image if needed
4. rerun terraform apply if Cloud Run Job needed the image
5. run Cloud Build deployment
6. execute Cloud Run Job
7. inspect Cloud Run logs
```

## Composer note

Cloud Composer is not provisioned by default.

The project includes an Airflow DAG that is designed to be Composer-compatible, but Composer is intentionally left optional because it can create ongoing cost.

For a production deployment, the DAG would be uploaded to a Composer environment and scheduled there.
