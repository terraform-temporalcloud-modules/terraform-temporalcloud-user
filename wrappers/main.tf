module "wrapper" {
  source = "../"

  for_each = var.items

  account_access              = try(each.value.account_access, var.defaults.account_access, "")
  account_access_custom_roles = try(each.value.account_access_custom_roles, var.defaults.account_access_custom_roles, null)
  create_user                 = try(each.value.create_user, var.defaults.create_user, true)
  email                       = try(each.value.email, var.defaults.email, "")
  namespace_accesses          = try(each.value.namespace_accesses, var.defaults.namespace_accesses, null)
  timeouts                    = try(each.value.timeouts, var.defaults.timeouts, {})
}
