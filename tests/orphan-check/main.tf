# Reports test resources still present in the account.
#
# Creates nothing: two data sources and outputs only. `terraform test` destroys
# what it creates, including after a failed assertion, but a cancelled or crashed
# run can leave something behind and nothing else would notice.
#
# This matters more here than elsewhere in the module family. A leftover user is
# a real pending account member holding real access and a real seat, so CI runs
# the check after the apply tests always — including when they fail, which is
# when something is most likely to have been abandoned.
#
# Both resource types the suite creates are covered:
#
#   - users, created by the applying tests themselves
#   - namespaces, created by the gated fixture in tests/setup that
#     namespace_accesses needs
#
# Both carry the same `yulei-tftest-usr-` prefix, so one variable filters both.
#
# Run after the apply tests. Anything reported here is a leftover.

data "temporalcloud_users" "all" {}

data "temporalcloud_namespaces" "all" {}

locals {
  orphan_users = [
    for u in data.temporalcloud_users.all.users : u.email
    if startswith(u.email, var.test_resource_prefix)
  ]

  orphan_namespaces = [
    for n in data.temporalcloud_namespaces.all.namespaces : n.name
    if startswith(n.name, var.test_resource_prefix)
  ]

  orphans = concat(local.orphan_users, local.orphan_namespaces)
}
