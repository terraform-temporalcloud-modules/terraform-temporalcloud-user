output "user_id" {
  description = "The unique identifier of the user"
  value       = module.user.user_id
}

output "user_email" {
  description = "The address the invitation was sent to"
  value       = module.user.user_email
}

output "user_state" {
  description = "Whether the invitation has been accepted — `active` once it has"
  value       = module.user.user_state
}

output "user_namespace_accesses" {
  description = "The user's complete namespace access map"
  value       = module.user.user_namespace_accesses
}

output "user_account_access_custom_roles" {
  description = "Custom roles granted on top of the built-in account role"
  value       = module.user.user_account_access_custom_roles
}
