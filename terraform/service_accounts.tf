# Creates service accounts and grants their required project-level IAM roles.

resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
}

locals {
  service_account_iam_roles = flatten([
    for service_account_name, service_account in var.service_accounts : [
      for role in service_account.roles : {
        key                  = "${service_account_name}-${role}"
        service_account_name = service_account_name
        role                 = role
      }
    ]
  ])
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for binding in local.service_account_iam_roles : binding.key => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account_name].email}"
}