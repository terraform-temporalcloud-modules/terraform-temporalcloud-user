// Main lifecycle: create a real user, then update it in place across run blocks.
//
// This applies against a live Temporal Cloud account. It creates a genuine
// pending account member, changes its access, and destroys it again — which is
// the only thing that proves the API accepts the values this module sends, as
// opposed to their shape.
//
// SAFETY. Every address comes from tests/setup, whose domain is example.com,
// reserved by RFC 2606 and permanently unroutable: the domain has no MX record
// and cannot be given one, so no invitation can reach a human being. The `setup`
// run block asserts that domain, and a failed run block makes every later one
// skip, so nothing below can invite anybody if the fixture is ever repointed.
//
// Creates ONE user and updates it across run blocks rather than one per case.
// Run blocks share state within a file, so a later block with different
// variables updates the same user — which is also how "an update is not a
// replacement" gets proved, by comparing user_id back to the ID the create block
// returned. Never compare an output to a value the same block passed in: that
// holds even when the resource was destroyed and recreated underneath it.
//
// `email` forces replacement, so it is held constant across every block below.
// Changing it would revoke the previous address and send a fresh invitation
// rather than updating anything.
//
// terraform test destroys everything it created when the file finishes, including
// after a failed assertion.

provider "temporalcloud" {
  // Reads TEMPORAL_CLOUD_API_KEY from the environment. The module under test
  // declares no provider block, by design for a published module, so the test
  // supplies one.
}

run "setup" {
  module {
    source = "./tests/setup"
  }

  // The safety property the rest of this file rests on. `output.email_domain`,
  // not `run.setup.email_domain`: a run block addresses its own outputs bare,
  // and naming itself is rejected as a self reference.
  assert {
    condition     = output.email_domain == "example.com"
    error_message = "tests/setup is pointed at a domain other than the undeliverable RFC 2606 default; no run block in this file may invite an address that can receive mail"
  }
}

################################################################################
# account_access
################################################################################

run "create_user" {
  variables {
    email = run.setup.user_email

    // `read` first, so the next block can prove the role is mutable in place.
    // Not `admin` or `owner`: admin reaches every namespace implicitly, which
    // rules out the namespace_accesses coverage below, and owner cannot be
    // created at all.
    account_access = "read"

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = output.user_id != ""
    error_message = "user_id is empty, so no user was created"
  }

  assert {
    condition     = output.user_email == run.setup.user_email
    error_message = "user_email output did not echo the address the invitation was sent to"
  }

  assert {
    condition     = output.user_account_access == "read"
    error_message = "account_access did not round-trip through the API, got: ${output.user_account_access}"
  }

  // The state the API assigns, which is unknowable at plan time and so was
  // previously unasserted. `activating` while the record is being provisioned,
  // `active` once it is; anything else — and in particular `activationfailed` —
  // means the create did not do what it reported.
  assert {
    condition     = contains(["activating", "active"], lower(output.user_state))
    error_message = "user_state came back as '${output.user_state}', not a healthy state for a freshly created user"
  }

  assert {
    // length(), not == toset([]): the output comes from try(..., []) so it is a
    // tuple, which never compares equal to a set.
    condition     = length(output.user_namespace_accesses) == 0
    error_message = "expected no namespace accesses before any were requested"
  }

  assert {
    condition     = length(output.user_account_access_custom_roles) == 0
    error_message = "expected no custom roles before any were requested"
  }
}

// The account role is mutable in place. `developer` because the namespace grants
// below need an account role that does not already reach every namespace.
run "change_account_access" {
  variables {
    email          = run.setup.user_email
    account_access = "developer"

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = output.user_account_access == "developer"
    error_message = "account_access was not updated in place, got: ${output.user_account_access}"
  }

  // Compared against the ID create_user returned. A non-empty ID, or an email
  // matching the one this block passed in, would both still be reported by a
  // replacement invited in the original's place — only the ID tells an update
  // apart from a destroy-and-recreate.
  assert {
    condition     = output.user_id == run.create_user.user_id
    error_message = "the user was replaced rather than having its account role updated in place"
  }

  assert {
    condition     = !contains(["activationfailed", "updatefailed"], lower(output.user_state))
    error_message = "user_state came back as '${output.user_state}' after the role change"
  }
}

################################################################################
# namespace_accesses
#
# Needs a real namespace: Temporal Cloud rejects a namespace ID that is not in
# the account, so this cannot be covered with a placeholder.
################################################################################

// Switches on the gated namespace in tests/setup. Deliberately placed *after*
// the account-access coverage: this is the only fixture in the file that can
// fail for account-specific reasons — a namespace quota, or a region the account
// is not entitled to — and a failed run block makes every later one skip rather
// than fail. Sitting here, such a failure costs the namespace coverage only.
run "setup_namespace" {
  module {
    source = "./tests/setup"
  }

  variables {
    create_namespace_fixture = true
  }

  assert {
    condition     = output.namespace_id != ""
    error_message = "the namespace fixture reported no ID, so namespace_accesses has nothing to point at"
  }
}

run "add_namespace_access" {
  variables {
    email          = run.setup.user_email
    account_access = "developer"

    namespace_accesses = [
      {
        namespace_id = run.setup_namespace.namespace_id
        permission   = "write"
      },
    ]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  // Adding a grant must not have re-invited the person.
  assert {
    condition     = output.user_id == run.create_user.user_id
    error_message = "the user was replaced rather than having a namespace grant added"
  }

  assert {
    condition     = length(output.user_namespace_accesses) == 1
    error_message = "expected 1 namespace access, got ${length(output.user_namespace_accesses)}"
  }

  assert {
    condition     = tolist(output.user_namespace_accesses)[0].namespace_id == run.setup_namespace.namespace_id
    error_message = "the namespace access did not come back pointing at the fixture namespace"
  }

  assert {
    condition     = tolist(output.user_namespace_accesses)[0].permission == "write"
    error_message = "the namespace permission did not round-trip through the API"
  }
}

// The permission is mutable in place, and the set is replaced wholesale rather
// than merged into.
run "change_namespace_permission" {
  variables {
    email          = run.setup.user_email
    account_access = "developer"

    namespace_accesses = [
      {
        namespace_id = run.setup_namespace.namespace_id
        permission   = "read"
      },
    ]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = output.user_id == run.create_user.user_id
    error_message = "the user was replaced while its namespace permission changed"
  }

  assert {
    condition     = length(output.user_namespace_accesses) == 1
    error_message = "expected the access set to be replaced, not appended to, got ${length(output.user_namespace_accesses)} entries"
  }

  assert {
    condition     = tolist(output.user_namespace_accesses)[0].namespace_id == run.setup_namespace.namespace_id
    error_message = "the namespace access stopped pointing at the fixture namespace"
  }

  assert {
    condition     = tolist(output.user_namespace_accesses)[0].permission == "read"
    error_message = "the namespace permission was not updated in place, got: ${tolist(output.user_namespace_accesses)[0].permission}"
  }
}

// Omitting the variable revokes the grant. This block is also what makes the
// teardown order irrelevant: it leaves the user holding nothing against the
// fixture namespace, so whichever of the two is destroyed first, neither is
// blocked by the other.
run "remove_namespace_accesses" {
  variables {
    email          = run.setup.user_email
    account_access = "developer"

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = length(output.user_namespace_accesses) == 0
    error_message = "omitting namespace_accesses should revoke every grant, but ${length(output.user_namespace_accesses)} remain"
  }

  // The SAME user must survive losing the grant, not merely some user: a
  // non-empty ID would also be reported by a replacement invited in its place.
  assert {
    condition     = output.user_id == run.create_user.user_id
    error_message = "the user should survive losing its namespace grants, with the same ID"
  }

  assert {
    condition     = output.user_account_access == "developer"
    error_message = "the account role should be untouched by removing namespace grants, got: ${output.user_account_access}"
  }

  assert {
    condition     = contains(["activating", "active"], lower(output.user_state))
    error_message = "user_state came back as '${output.user_state}' after the final update"
  }
}
