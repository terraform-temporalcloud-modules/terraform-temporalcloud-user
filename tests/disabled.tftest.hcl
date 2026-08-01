// Verifies create_user = false against a real provider.
//
// Applies, but creates nothing: the gate is off, so the point of the file is
// that no user is invited and every output falls back through try().
//
// It still configures the provider, which is why it needs TEMPORAL_CLOUD_API_KEY.

provider "temporalcloud" {}

run "creates_nothing" {
  variables {
    create_user = false

    // Supplied because the provider marks both attributes required, so neither
    // variable has a default. Nothing is created, so the empty values never
    // reach the API — the resource is counted out before they are used.
    email          = ""
    account_access = ""
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
