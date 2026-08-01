#!/usr/bin/env bash
#
# Fails if the test suite left anything behind.
#
# The apply tests create real users and, for the namespace_accesses coverage, a
# throwaway namespace. `terraform test` destroys both when a file finishes, but a
# cancelled or crashed runner does not — and a leftover user is a real pending
# account member holding a real seat, so this check is the backstop for the
# worst outcome the suite can produce.
#
# Both resource types carry the `yulei-tftest-usr-` prefix, and the
# temporalcloud_users and temporalcloud_namespaces data sources enumerate them.
#
# Requires TEMPORAL_CLOUD_API_KEY. Creates nothing — tests/orphan-check contains
# data sources and outputs only.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)/tests/orphan-check"

terraform init -backend=false -no-color >/dev/null
terraform apply -auto-approve -no-color >/dev/null

count="$(terraform output -raw orphan_count)"
user_count="$(terraform output -raw orphan_user_count)"

if [ "$count" -eq 0 ]; then
  echo "No leftover test users or namespaces."
  exit 0
fi

echo "ERROR: $count leftover test resource(s) after the suite finished," >&2
echo "       $user_count of which are users:" >&2
terraform output -json orphans | sed 's/[][",]/ /g' | tr -s ' ' '\n' | sed '/^$/d;s/^/  - /' >&2
echo >&2
echo "These were not destroyed. Remove them in the Temporal Cloud UI, or import and" >&2
echo "destroy them. Removing a user revokes that person's access to the account, so" >&2
echo "confirm each address belongs to the test suite before deleting it." >&2
exit 1
