provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

################################################################################
# Read-only user on an existing namespace
#
# The narrowest useful grant: the person can sign in and inspect workflows in one
# namespace, and can change nothing anywhere. This is the shape most audit,
# support and on-call-observer accounts should take.
#
# Unlike the `complete` example, nothing is created here except the user — the
# namespace already exists and is referenced by ID, which is the usual case once
# an account is established.
#
# Applying this sends an invitation email to `var.email`.
################################################################################

module "user" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 1.0"

  email = var.email

  # Account-wide read: the person can sign in and list namespaces, but the grant
  # below is what lets them see anything inside one.
  account_access = "read"

  namespace_accesses = [
    {
      namespace_id = var.namespace_id
      permission   = "read"
    },
  ]
}
