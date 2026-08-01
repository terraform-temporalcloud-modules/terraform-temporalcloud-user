provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

################################################################################
# Local regression coverage
#
# The examples/ directories source the PUBLISHED module so they are copy-pasteable
# for consumers. That means they validate the last release, not the code in this
# repo — a renamed or removed variable would slip through CI unnoticed.
#
# This directory closes that gap: it sources the module by relative path and
# passes EVERY input, so `terraform validate` fails here the moment the variable
# surface changes incompatibly. CI picks it up automatically because it contains a
# versions.tf with required_version.
#
# Nothing here is ever applied. It carries the whole input surface of a module
# whose apply layer cannot invite anyone, so it is the only gate most inputs get —
# see tests/README.md. Every address uses example.com, reserved by RFC 2606 and
# unable to receive mail.
#
# When you add a variable to the root module, add it here in the same PR. Adding
# it to examples/ has to wait until the next release publishes it.
################################################################################

# Every input the module accepts.
module "all_inputs" {
  source = "../../"

  create_user = true

  email          = "tflocal-all-inputs@example.com"
  account_access = "developer"

  account_access_custom_roles = ["00000000000000000000000000000000"]

  namespace_accesses = [
    {
      namespace_id = "tflocal-orders.a1b2c"
      permission   = "write"
    },
    {
      namespace_id = "tflocal-payments.a1b2c"
      permission   = "read"
    },
  ]

  timeouts = {
    create = "10m"
    delete = "10m"
  }
}

# The create flag off: proves the module produces no resources and that every
# output still evaluates via its try() fallback.
module "disabled" {
  source = "../../"

  create_user = false
}

# Minimum viable call: only the two required-in-practice inputs.
module "minimal" {
  source = "../../"

  email          = "tflocal-minimal@example.com"
  account_access = "read"
}

# An account-level admin, which reaches every namespace implicitly and therefore
# must carry no namespace_accesses.
module "account_admin" {
  source = "../../"

  email          = "tflocal-admin@example.com"
  account_access = "admin"
}

# The wrapper, exercised through the local path as well.
module "wrapper" {
  source = "../../wrappers"

  defaults = {
    account_access = "read"
  }

  items = {
    ana = { email = "tflocal-ana@example.com" }
    ben = {
      email          = "tflocal-ben@example.com"
      account_access = "developer"

      namespace_accesses = [
        {
          namespace_id = "tflocal-orders.a1b2c"
          permission   = "admin"
        },
      ]
    }
  }
}
