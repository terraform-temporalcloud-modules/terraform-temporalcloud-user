#!/usr/bin/env bash
#
# Liveness check: confirms the Temporal Cloud API answers and the API key works.
#
# Run this before the apply tests so a credentials or connectivity problem fails
# immediately and unambiguously, instead of surfacing minutes later as a plan that
# would not build.
#
# Creates nothing — tests/liveness reads one data source.

set -euo pipefail

if [ -z "${TEMPORAL_CLOUD_API_KEY:-}" ]; then
  echo "ERROR: TEMPORAL_CLOUD_API_KEY is not set." >&2
  echo "       The apply tests configure a real provider and cannot run without it." >&2
  exit 1
fi

cd "$(git rev-parse --show-toplevel)/tests/liveness"

if ! terraform init -backend=false -no-color >/dev/null 2>&1; then
  echo "ERROR: terraform init failed for the liveness check." >&2
  terraform init -backend=false -no-color 2>&1 | tail -20 >&2
  exit 1
fi

if ! output="$(terraform apply -auto-approve -no-color 2>&1)"; then
  echo "ERROR: Temporal Cloud API is unreachable or the API key was rejected." >&2
  echo >&2
  printf '%s\n' "$output" | tail -20 >&2
  echo >&2
  echo "Check that TEMPORAL_CLOUD_API_KEY is set to a current, unexpired key with" >&2
  echo "access to the intended account." >&2
  exit 1
fi

count="$(terraform output -raw user_count)"

if [ "$count" -eq 0 ]; then
  echo "ERROR: the API answered but reported no users at all." >&2
  echo "       Every account has at least one user, so a zero count means the key" >&2
  echo "       cannot read identity resources and the tests would fail for reasons" >&2
  echo "       unrelated to this module." >&2
  exit 1
fi

echo "API reachable, key accepted. $count user(s) on the account, in state(s):"
terraform output -json user_states | sed 's/[][",]/ /g' | tr -s ' ' '\n' | sed '/^$/d;s/^/  - /'
