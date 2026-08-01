# Referencing every output forces Terraform to evaluate each one, so a broken
# output expression fails validation here rather than in a consumer's plan.

output "all_inputs" {
  description = "Every output of the fully configured module instance"
  value = {
    user_id                          = module.all_inputs.user_id
    user_email                       = module.all_inputs.user_email
    user_state                       = module.all_inputs.user_state
    user_account_access              = module.all_inputs.user_account_access
    user_account_access_custom_roles = module.all_inputs.user_account_access_custom_roles
    user_namespace_accesses          = module.all_inputs.user_namespace_accesses
  }
}

output "disabled" {
  description = "Outputs when create_user is false — every one must fall back rather than error"
  value = {
    user_id                          = module.disabled.user_id
    user_email                       = module.disabled.user_email
    user_state                       = module.disabled.user_state
    user_account_access              = module.disabled.user_account_access
    user_account_access_custom_roles = module.disabled.user_account_access_custom_roles
    user_namespace_accesses          = module.disabled.user_namespace_accesses
  }
}

output "minimal" {
  description = "Outputs from the minimum viable module call"
  value       = module.minimal.user_id
}

output "account_admin" {
  description = "Outputs from the account-level admin, which carries no namespace grants"
  value = {
    user_id                 = module.account_admin.user_id
    user_account_access     = module.account_admin.user_account_access
    user_namespace_accesses = module.account_admin.user_namespace_accesses
  }
}

output "wrapper" {
  description = "Wrapper outputs, keyed by item name"
  value       = module.wrapper.wrapper
}
