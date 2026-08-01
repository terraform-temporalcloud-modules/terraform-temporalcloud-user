// Plan-only coverage of the full input surface.
//
// Every run block here is `command = plan`, so Terraform builds the payload the
// provider would send and then stops. Nothing is created and nobody is invited,
// which is the only form of provider-backed coverage this module can have — see
// tests/README.md.
//
// The provider still authenticates at configure time, so these need
// TEMPORAL_CLOUD_API_KEY even though they create nothing.
//
// What this proves: the provider accepts the shape of the configuration this
// module generates, and the module's own validation and preconditions agree with
// it. What it cannot prove: that the Temporal Cloud API accepts the values, since
// that is only checked on apply.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }

  // The safety property the rest of this suite rests on. Every address planned
  // against below comes from here, so if the domain is ever repointed at
  // somewhere deliverable this stops the run before a plan is built. Nothing
  // downstream executes once a setup assertion fails, which is what is wanted:
  // no block in this file should plan against an address that can receive mail.
  // `output.email_domain`, not `run.setup.email_domain`: a run block addresses
  // its own outputs bare, and naming itself is rejected as a self reference.
  assert {
    condition     = output.email_domain == "example.com"
    error_message = "tests/setup is pointed at a domain other than the undeliverable RFC 2606 default; no run block in this file may plan against an address that can receive mail"
  }
}

run "plan_full" {
  command = plan

  variables {
    email          = run.setup.user_email
    account_access = "developer"

    // Exercised here and not only in `local/`, so the provider sees the shape
    // the module builds for it. The ID is a placeholder in the right form; plan
    // never resolves it against the account.
    account_access_custom_roles = ["00000000000000000000000000000000"]

    namespace_accesses = [
      {
        namespace_id = "tfplan-orders.a1b2c"
        permission   = "write"
      },
      {
        namespace_id = "tfplan-payments.a1b2c"
        permission   = "read"
      },
    ]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  // Only attributes that are known at plan time can be asserted on. `user_id`
  // and `user_state` are assigned by the API and stay unknown until apply.
  assert {
    condition     = output.user_email == run.setup.user_email
    error_message = "user_email output did not echo the requested address"
  }

  assert {
    condition     = output.user_account_access == "developer"
    error_message = "user_account_access output did not echo the requested role"
  }

  assert {
    condition     = length(output.user_account_access_custom_roles) == 1
    error_message = "account_access_custom_roles did not reach the planned resource"
  }

  assert {
    condition     = length(output.user_namespace_accesses) == 2
    error_message = "expected 2 namespace grants in the plan, got ${length(output.user_namespace_accesses)}"
  }

  // The count alone would hold if the grants were mangled — a dropped
  // permission, or the two namespace IDs paired with each other's permission,
  // both leave two elements. These pin each pair down.
  assert {
    condition = length([
      for access in output.user_namespace_accesses : access
      if access.namespace_id == "tfplan-orders.a1b2c" && access.permission == "write"
    ]) == 1
    error_message = "the orders namespace was not granted `write` in the plan"
  }

  assert {
    condition = length([
      for access in output.user_namespace_accesses : access
      if access.namespace_id == "tfplan-payments.a1b2c" && access.permission == "read"
    ]) == 1
    error_message = "the payments namespace was not granted `read` in the plan"
  }
}

// An account admin reaches every namespace implicitly. The module refuses the
// combination in a precondition so it fails during plan rather than as an API
// error minutes into an apply.
run "plan_admin_rejects_namespace_accesses" {
  command = plan

  variables {
    email          = run.setup.user_email
    account_access = "admin"

    namespace_accesses = [
      {
        namespace_id = "tfplan-orders.a1b2c"
        permission   = "read"
      },
    ]
  }

  expect_failures = [
    temporalcloud_user.this,
  ]
}

run "plan_wrapper" {
  command = plan

  module {
    source = "./wrappers"
  }

  variables {
    defaults = {
      account_access = "read"
    }

    items = {
      ana = { email = "ana-${run.setup.user_email}" }
      ben = {
        email = "ben-${run.setup.user_email}"
        // Overrides the shared default above.
        account_access = "developer"
      }
    }
  }

  assert {
    condition     = length(output.wrapper) == 2
    error_message = "expected 2 users from the wrapper, got ${length(output.wrapper)}"
  }

  assert {
    condition     = output.wrapper["ana"].user_account_access == "read"
    error_message = "defaults.account_access did not reach the ana item"
  }

  assert {
    condition     = output.wrapper["ben"].user_account_access == "developer"
    error_message = "the ben item did not override defaults.account_access"
  }
}
