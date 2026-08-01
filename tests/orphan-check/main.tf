# Reports test users still present in the account.
#
# Creates nothing: a data source and outputs only.
#
# The apply tests in this repository deliberately never create a user, so a clean
# run always reports zero. The check is still real rather than a stub: the
# temporalcloud_users data source can enumerate every user on the account, so this
# catches a user left behind by a maintainer who pointed tests/setup at a real
# domain and ran an apply test by hand.
#
# Run after the apply tests. Anything reported here is a leftover.

data "temporalcloud_users" "all" {}

locals {
  orphans = [
    for u in data.temporalcloud_users.all.users : u.email
    if startswith(u.email, var.test_email_prefix)
  ]
}
