output "user_id" {
  description = "The unique identifier of the user"
  value       = module.user.user_id
}

output "user_state" {
  description = "The provisioning state of the user record — not a signal that the invitation was accepted"
  value       = module.user.user_state
}

output "user_namespace_accesses" {
  description = "The user's complete namespace access map"
  value       = module.user.user_namespace_accesses
}
