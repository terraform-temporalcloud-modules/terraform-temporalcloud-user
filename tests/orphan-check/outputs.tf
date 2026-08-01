output "orphans" {
  description = "Test resources still present in the account: email addresses of leftover users, then names of leftover namespaces"
  value       = local.orphans
}

output "orphan_count" {
  description = "Number of test resources still present, users and namespaces together"
  value       = length(local.orphans)
}

output "orphan_user_count" {
  description = "Number of leftover users. Reported separately because a leftover user holds real access and a real account seat, which a leftover namespace does not"
  value       = length(local.orphan_users)
}
