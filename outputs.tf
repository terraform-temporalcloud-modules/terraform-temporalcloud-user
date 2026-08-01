################################################################################
# User
#
# Outputs are wrapped in `try()` so they still evaluate to an empty value when
# `create_user = false` leaves no resource to reference. The two set-typed
# outputs additionally pass through `coalesce()`, because the underlying
# attributes are null — not empty — when nothing is assigned, and `try()` returns
# a null unchanged.
################################################################################

output "user_id" {
  description = "The unique identifier of the user. This is the ID other resources reference, for example `temporalcloud_group_members.users`"
  value       = try(temporalcloud_user.this[0].id, "")
}

output "user_email" {
  description = "The email address the invitation was sent to"
  value       = try(temporalcloud_user.this[0].email, "")
}

output "user_state" {
  description = "The current state of the user, as reported by Temporal Cloud. `active` means the person has accepted their invitation and the account is usable; while an invitation is outstanding the user reports `activating` instead, and `expired` once an unaccepted invitation lapses. Other values are `updating`, `suspended`, `deleting`, `deleted`, and the `activationfailed`, `updatefailed` and `deletefailed` error states"
  value       = try(temporalcloud_user.this[0].state, "")
}

################################################################################
# Access
################################################################################

output "user_account_access" {
  description = "The account-level role granted to the user"
  value       = try(temporalcloud_user.this[0].account_access, "")
}

output "user_account_access_custom_roles" {
  description = "IDs of the custom roles granted to the user in addition to the built-in account role. Empty when none are assigned"
  value       = try(coalesce(temporalcloud_user.this[0].account_access_custom_roles, toset([])), toset([]))
}

output "user_namespace_accesses" {
  description = "The user's complete namespace access map, as `namespace_id` and `permission` pairs. Empty for account roles that reach every namespace implicitly"
  value       = try(coalesce(temporalcloud_user.this[0].namespace_accesses, toset([])), toset([]))
}
