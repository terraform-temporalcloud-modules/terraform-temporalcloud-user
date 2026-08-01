output "user_count" {
  description = "Number of users the API returned. Any value above zero means the API answered and the key was accepted — an account always has at least one user"
  value       = length(data.temporalcloud_users.liveness.users)
}

output "user_states" {
  description = "Distinct user states present on the account, reported so a failing suite shows what the account actually looks like"
  value       = distinct(sort([for u in data.temporalcloud_users.liveness.users : u.state]))
}
