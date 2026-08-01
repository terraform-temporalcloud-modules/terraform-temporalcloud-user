locals {
  create_user = var.create_user
}

################################################################################
# User
#
# Creating this resource invites a real person: Temporal Cloud emails an
# invitation to `email`, which they must accept before they can sign in.
# Destroying it revokes that person's access to the account.
#
# Check whether the account has SCIM before reaching for this module. SCIM
# provisions people and their group memberships from an identity provider, so
# managing the same people here means two systems writing the same records. What
# SCIM does not assign is permissions — grant those to a SCIM-provisioned group
# through the `group` module and let membership carry them. This module suits
# accounts without SCIM, break-glass administrators held outside the identity
# provider, people absent from the directory, and one-off exceptions. Workers and
# CI authenticate with a service account and an API key, never a user. README.md
# sets out the full split.
#
# `namespace_accesses` is a nested attribute in the provider schema rather than a
# block, so it is assigned straight from its variable and a null value omits it.
# `timeouts` is the only true block, hence the dynamic block below.
################################################################################

resource "temporalcloud_user" "this" {
  count = local.create_user ? 1 : 0

  # Changing the email address replaces the user, which revokes the old address
  # and sends a fresh invitation to the new one.
  email = var.email

  account_access              = var.account_access
  account_access_custom_roles = var.account_access_custom_roles
  namespace_accesses          = var.namespace_accesses

  dynamic "timeouts" {
    for_each = length([for v in var.timeouts : v if v != null]) > 0 ? [var.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    # Owners and admins reach every namespace implicitly, and the provider
    # refuses explicit grants for them. Cross-variable checks are not allowed in
    # a `validation` block until Terraform 1.9, above this module's floor, so it
    # is a precondition instead — which also names the module inputs rather than
    # the resource attribute the provider's own validator points at.
    precondition {
      condition     = !contains(["owner", "admin"], lower(var.account_access)) || var.namespace_accesses == null
      error_message = "namespace_accesses cannot be combined with an account_access of owner or admin: those roles already have access to every namespace."
    }
  }
}
