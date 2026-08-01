provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  # example.com is reserved by RFC 2606 and can never receive mail, so applying
  # this example as written invites nobody. Replace it with a real colleague's
  # address only when you mean to send them an invitation.
  email = "developer@example.com"
}

################################################################################
# Supporting resources
#
# A user grant has to point at something, so this example creates the namespace
# and the custom role it references. In a real configuration these usually
# already exist and you would reference their IDs instead.
################################################################################

# The regions an account may use are a subset of the published list, so this
# reads the account's own entitlements rather than hardcoding an ID.
data "temporalcloud_regions" "available" {}

resource "temporalcloud_namespace" "orders" {
  name           = "ex-user-orders"
  regions        = [sort([for r in data.temporalcloud_regions.available.regions : r.id])[0]]
  retention_days = 1
  api_key_auth   = true
}

resource "temporalcloud_custom_role" "billing_reader" {
  name        = "ex-user-billing-reader"
  description = "Reads account-level billing information."

  permissions = [
    {
      actions = ["cloud.account.get"]
      resources = {
        resource_type = "accounts"
        resource_ids  = []
        allow_all     = true
      }
    },
  ]
}

################################################################################
# Complete: every input this module supports
#
# Applying this sends an invitation email to `local.email`. The user is not
# usable until the person accepts it, and `terraform destroy` revokes their
# access to the account.
################################################################################

module "user" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 2.0"

  email = local.email

  # Built-in account role. `admin` and `owner` reach every namespace implicitly
  # and cannot be combined with namespace_accesses, so this uses `developer`.
  account_access = "developer"

  # Custom roles stack on top of the built-in role rather than replacing it.
  account_access_custom_roles = [temporalcloud_custom_role.billing_reader.id]

  # This set is the user's complete namespace access map — removing an entry
  # revokes that access. Add further namespaces as additional entries:
  #
  #   {
  #     namespace_id = temporalcloud_namespace.payments.id
  #     permission   = "read"
  #   },
  namespace_accesses = [
    {
      namespace_id = temporalcloud_namespace.orders.id
      permission   = "write"
    },
  ]

  timeouts = {
    create = "10m"
    delete = "10m"
  }
}
