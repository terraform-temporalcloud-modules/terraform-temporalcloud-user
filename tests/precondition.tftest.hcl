// The module's own precondition, exercised through plan so nothing is created.
//
// Plan-only on purpose, and not convertible: the block asserts that a
// configuration is *refused*, and a refusal has no apply to run. It sits apart
// from validation.tftest.hcl only because this one is enforced by a resource
// precondition rather than a variable validation, so it names the resource
// rather than the variable in expect_failures.
//
// The provider still authenticates at configure time, so this needs
// TEMPORAL_CLOUD_API_KEY even though it creates nothing.

provider "temporalcloud" {}

// An account admin reaches every namespace implicitly, and the provider refuses
// explicit grants for one. The module refuses the combination in a precondition
// so it fails during plan rather than as an API error minutes into an apply.
run "admin_rejects_namespace_accesses" {
  command = plan

  variables {
    email          = "admin-with-grants@example.com"
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
