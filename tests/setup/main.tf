# Fixtures for the applying tests.
#
# The address generator is unconditional and contacts nothing, so it cannot fail
# and cannot make the run blocks that depend on it skip. The namespace is gated
# off by default, because it is the one thing here that can fail for reasons
# outside this module — a region entitlement or a namespace quota.

# A unique address per run.
#
# Temporal Cloud allows one user per email address in an account, so a fixed
# address would make a second run — or a concurrent one — fail on an address
# already invited, and would collide with anything left behind by an interrupted
# run.
#
# The domain is example.com, reserved by RFC 2606 and unable to receive mail, so
# nothing generated here can reach a person even though the suite really does
# create users. Every applying run block asserts that domain before it invites
# anybody — see tests/README.md.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}

locals {
  # `yulei-` identifies the owner, `tftest-usr-` distinguishes this module's test
  # resources from the rest of the family's. scripts/check-orphans.sh filters on
  # exactly this prefix, so everything generated here has to start with it —
  # including the derived addresses tests build from `user_email_prefix`.
  name_prefix = "yulei-tftest-usr-${random_pet.this.id}"
}

# Regions this account is entitled to use.
#
# Not hardcoded: the regions an account may use are a subset of the published
# list, so a fixed ID makes the suite account-specific and can fail with
# "is not a valid Temporal Cloud region".
data "temporalcloud_regions" "available" {}

locals {
  # Sorted so repeat runs pick the same region and results stay comparable.
  region_ids = sort([for r in data.temporalcloud_regions.available.regions : r.id])
}

# A throwaway namespace for `namespace_accesses` to point at.
#
# Temporal Cloud rejects a namespace ID that does not name a namespace already in
# the account, so a placeholder cannot stand in, and no data source enumerates
# namespaces guaranteed to be present on an arbitrary account.
#
# Off by default: only the run block that needs it switches it on, so a namespace
# quota or a region entitlement cannot skip the account-access coverage that runs
# before it.
resource "temporalcloud_namespace" "fixture" {
  count = var.create_namespace_fixture ? 1 : 0

  name           = local.name_prefix
  regions        = [local.region_ids[0]]
  retention_days = 1
  api_key_auth   = true
}
