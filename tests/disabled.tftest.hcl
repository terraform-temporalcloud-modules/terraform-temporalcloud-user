// Verifies create_user = false against a real provider.
//
// This is the only file in the suite that applies. It creates nothing and
// therefore invites nobody, which is the whole reason it is safe to run — see
// tests/README.md for why the rest of the input surface has no apply coverage.
//
// It still configures the provider, which is why it needs TEMPORAL_CLOUD_API_KEY.

provider "temporalcloud" {}

run "creates_nothing" {
  variables {
    create_user = false
  }

  // Every output is count-gated behind try(); these assertions prove the
  // fallbacks evaluate rather than erroring when the module is switched off.
  assert {
    condition     = output.user_id == ""
    error_message = "user_id should fall back to empty when create_user = false"
  }

  assert {
    condition     = output.user_email == ""
    error_message = "user_email should fall back to empty when create_user = false"
  }

  assert {
    condition     = output.user_state == ""
    error_message = "user_state should fall back to empty when create_user = false"
  }

  assert {
    condition     = output.user_account_access == ""
    error_message = "user_account_access should fall back to empty"
  }

  assert {
    // length(), not == toset([]): the output is a tuple, which never compares
    // equal to a set.
    condition     = length(output.user_account_access_custom_roles) == 0
    error_message = "user_account_access_custom_roles should fall back to an empty set"
  }

  assert {
    condition     = length(output.user_namespace_accesses) == 0
    error_message = "user_namespace_accesses should fall back to an empty set"
  }
}
