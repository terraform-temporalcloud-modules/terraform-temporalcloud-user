output "user_id" {
  description = "The unique identifier of the user"
  value       = module.user.user_id
}

output "user_state" {
  description = "Whether the invitation has been accepted — `active` once it has"
  value       = module.user.user_state
}

output "user_namespace_accesses" {
  description = "The user's complete namespace access map"
  value       = module.user.user_namespace_accesses
}
