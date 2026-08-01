output "user_email" {
  description = "Unique email address for this test run, with the local part prefixed `tftest-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account"
  value       = "tftest-${random_pet.this.id}@${var.test_email_domain}"
}

output "email_domain" {
  description = "The domain the generated address uses. Surfaced so a test run records whether it was pointed at the undeliverable default or at a real domain"
  value       = var.test_email_domain
}
