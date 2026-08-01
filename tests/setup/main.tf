# Generates a unique email address per test run.
#
# Temporal Cloud allows one user per email address in an account, so a fixed
# address would make a second run — or a concurrent one — fail on an address
# already invited, and would collide with anything a human left behind after a
# failed run.
#
# The default domain is example.com, reserved by RFC 2606 and unable to receive
# mail, so nothing generated here can reach a person. Overriding
# `test_email_domain` with a domain the account controls is the one change a
# maintainer needs to make in order to run an apply test that actually creates a
# user — see tests/README.md before doing that.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}
