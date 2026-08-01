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
}

run "plan_full" {
  command = plan

  variables {
    email          = run.setup.user_email
    account_access = "developer"

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
    condition     = length(output.user_namespace_accesses) == 2
    error_message = "expected 2 namespace grants in the plan, got ${length(output.user_namespace_accesses)}"
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
