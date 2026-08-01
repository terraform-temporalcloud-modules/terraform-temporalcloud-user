#!/usr/bin/env bash
#
# Fails if the test suite left users behind.
#
# The apply tests in this repository never create a user, so a clean run always
# reports zero. This is still a real check rather than a stub — the
# temporalcloud_users data source enumerates every user on the account — and it
# catches anything left behind by a maintainer who pointed tests/setup at a real
# domain and ran an applying test by hand.
#
# Requires TEMPORAL_CLOUD_API_KEY. Creates nothing — tests/orphan-check contains a
# data source and outputs only.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)/tests/orphan-check"

terraform init -backend=false -no-color >/dev/null
terraform apply -auto-approve -no-color >/dev/null

count="$(terraform output -raw orphan_count)"

if [ "$count" -eq 0 ]; then
  echo "No leftover test users."
  exit 0
fi

echo "ERROR: $count test user(s) still present after the suite finished:" >&2
terraform output -json orphans | sed 's/[][",]/ /g' | tr -s ' ' '\n' | sed '/^$/d;s/^/  - /' >&2
echo >&2
echo "These were not destroyed. Remove them in the Temporal Cloud UI, or import and" >&2
echo "destroy them. Removing a user revokes that person's access to the account, so" >&2
echo "confirm each address belongs to the test suite before deleting it." >&2
exit 1
