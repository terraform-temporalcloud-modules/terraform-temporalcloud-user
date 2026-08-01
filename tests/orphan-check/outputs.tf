output "orphans" {
  description = "Email addresses of test users still present in the account"
  value       = local.orphans
}

output "orphan_count" {
  description = "Number of test users still present"
  value       = length(local.orphans)
}
