##### PROJECT VARIABLES #####

variable "project_id" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
  default     = "centering-crow-496515-u6"
}

variable "region" {
  description = "The GCP region for Cloud Build resources."
  type        = string
  default     = "europe-west6"
}

##### INFORMATION ACCESS MANAGEMENT IAM VARIABLES #####

variable "service_accounts" {
  description = "Service accounts and their required project-level IAM roles."
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
    roles        = list(string)
  }))

  default = {
    dbt = {
      account_id   = "dbt-runner-sa"
      display_name = "dbt Runner Service Account"
      description  = "Service Account for DBT to interact with Google Cloud resources."
      roles = [
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
      ]
    }

    airflow = {
      account_id   = "airflow-runner-sa"
      display_name = "airflow Runner Service Account"
      description  = "Service Account for Airflow to interact with Google Cloud resources."
      roles = [
        "roles/bigquery.admin",
        "roles/storage.admin",
        "roles/run.invoker",
      ]
    }

    cloud_build = {
      account_id   = "cloudbuild-runner-sa"
      display_name = "cloud build Runner Service Account"
      description  = "Service Account for Cloud Build to interact with Google Cloud resources."
      roles = [
        "roles/bigquery.admin",
        "roles/storage.admin",
        "roles/artifactregistry.admin",
        "roles/run.developer",
        "roles/logging.logWriter",
        "roles/iam.serviceAccountUser",
      ]
    }
  }
}
