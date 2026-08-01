output "user_email" {
  description = "Unique address for the user a run creates, with the local part prefixed `yulei-tftest-usr-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account and visible to scripts/check-orphans.sh"
  value       = "${local.name_prefix}@${var.test_email_domain}"
}

output "user_email_prefix" {
  description = "Local part of `user_email`, for tests needing more than one address in a run. Suffix it rather than prefixing it, so the derived address still starts with the prefix the orphan check filters on"
  value       = local.name_prefix
}

output "email_domain" {
  description = "The domain the generated addresses use. Surfaced so every applying run block can assert it is the undeliverable RFC 2606 default before it invites anybody"
  value       = var.test_email_domain
}

output "namespace_id" {
  description = "ID of the throwaway namespace, for use in `namespace_accesses`. Empty unless `create_namespace_fixture` is true"
  value       = try(temporalcloud_namespace.fixture[0].id, "")
}

output "namespace_name" {
  description = "Name of the throwaway namespace, prefixed `yulei-tftest-usr-` so the orphan check can spot it if a run is interrupted. Empty unless `create_namespace_fixture` is true"
  value       = try(temporalcloud_namespace.fixture[0].name, "")
}
