// Variable validation, exercised through plan so nothing is created.
//
// Each run block passes a value the module should refuse and names the variable
// it expects to fail. A run block whose expected failure does not occur fails the
// suite, so these guard against a validation being weakened or dropped.

provider "temporalcloud" {}

run "rejects_unknown_account_access" {
  command = plan

  variables {
    email          = "invalid-role@example.com"
    account_access = "superuser"
  }

  expect_failures = [
    var.account_access,
  ]
}

run "rejects_malformed_email" {
  command = plan

  variables {
    email          = "not-an-address"
    account_access = "read"
  }

  expect_failures = [
    var.email,
  ]
}

run "rejects_unknown_namespace_permission" {
  command = plan

  variables {
    email          = "invalid-permission@example.com"
    account_access = "developer"

    namespace_accesses = [
      {
        namespace_id = "tfplan-orders.a1b2c"
        permission   = "owner"
      },
    ]
  }

  expect_failures = [
    var.namespace_accesses,
  ]
}

// The provider rejects empty sets rather than treating them as "no access", so
// the module refuses them up front and tells the caller to omit the variable.
run "rejects_empty_namespace_accesses" {
  command = plan

  variables {
    email              = "empty-accesses@example.com"
    account_access     = "developer"
    namespace_accesses = []
  }

  expect_failures = [
    var.namespace_accesses,
  ]
}

run "rejects_empty_custom_roles" {
  command = plan

  variables {
    email                       = "empty-roles@example.com"
    account_access              = "developer"
    account_access_custom_roles = []
  }

  expect_failures = [
    var.account_access_custom_roles,
  ]
}
