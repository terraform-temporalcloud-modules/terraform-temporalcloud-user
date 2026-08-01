// The wrappers submodule: several users from one call, with per-item overrides
// of the shared defaults.
//
// This is the only file that has more than one user alive at a time, which is
// the behaviour it exists to verify.
//
// Both addresses are derived from the tests/setup fixture by suffixing its local
// part, so they carry the `yulei-tftest-usr-` prefix scripts/check-orphans.sh
// filters on and stay on the undeliverable example.com domain.

provider "temporalcloud" {}

run "setup" {
  module {
    source = "./tests/setup"
  }

  assert {
    condition     = output.email_domain == "example.com"
    error_message = "tests/setup is pointed at a domain other than the undeliverable RFC 2606 default; no run block in this file may invite an address that can receive mail"
  }
}

run "create_many" {
  module {
    source = "./wrappers"
  }

  variables {
    defaults = {
      account_access = "read"
    }

    items = {
      ana = {
        email = "${run.setup.user_email_prefix}-ana@${run.setup.email_domain}"
        // Overrides the shared default above.
        account_access = "developer"
      }

      ben = {
        email = "${run.setup.user_email_prefix}-ben@${run.setup.email_domain}"
      }
    }
  }

  assert {
    condition     = length(output.wrapper) == 2
    error_message = "expected 2 users from the wrapper, got ${length(output.wrapper)}"
  }

  assert {
    condition     = output.wrapper["ana"].user_email == "${run.setup.user_email_prefix}-ana@${run.setup.email_domain}"
    error_message = "the ana item did not take its own address"
  }

  // Per-item values override the defaults rather than merging with them.
  assert {
    condition     = output.wrapper["ana"].user_account_access == "developer"
    error_message = "the per-item account_access did not override the default"
  }

  // Shared defaults reach every item.
  assert {
    condition     = output.wrapper["ben"].user_account_access == "read"
    error_message = "defaults.account_access did not reach the ben item"
  }

  // Two distinct users, not one instance reported twice.
  assert {
    condition     = output.wrapper["ana"].user_id != "" && output.wrapper["ben"].user_id != ""
    error_message = "one of the wrapper items was not created"
  }

  assert {
    condition     = output.wrapper["ana"].user_id != output.wrapper["ben"].user_id
    error_message = "both wrapper items reported the same user_id"
  }
}
