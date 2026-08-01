# Tests

Not usage examples — see [examples/](../examples) for those.

| Path | Runs on | Credentials |
| --- | --- | --- |
| `local/` | every pull request | no |
| `*.tftest.hcl` | on demand, weekly | **yes** |
| `setup/` | helper for `*.tftest.hcl` | no |

## The gap: no test invites anyone

**Nothing in this suite creates a `temporalcloud_user`, and nothing should.**

Creating one is not like creating a namespace. Temporal Cloud emails an invitation to the address, the
resource occupies a user seat on the account until it is destroyed, and destroying it revokes a real
person's access. A test that created a user would send mail on every scheduled run — to a real inbox if
the address resolved, or to a dead one if it did not, which is only marginally better. Neither belongs
in a job that runs weekly and unattended.

So the apply layer here is narrower than in the rest of this module family, and deliberately so. What
it does cover:

| File | Covers |
| --- | --- |
| `disabled.tftest.hcl` | `create_user = false` creates nothing and every output falls back. The only run block in the suite that applies |
| `plan.tftest.hcl` | Plan-only. The full input surface, the admin-plus-namespace-grants precondition, and the `wrappers` submodule |
| `validation.tftest.hcl` | Plan-only. Each variable validation refuses the value it is meant to refuse |

A `command = plan` run block builds the payload the provider would send and then stops, so it proves
the provider accepts the shape of what this module generates. It cannot prove the Temporal Cloud API
accepts the *values*: role names, custom role IDs and namespace IDs are only checked on apply.

That residual risk is carried by `local/` and by review, not by CI. For the affected inputs — `email`,
`account_access`, `account_access_custom_roles`, `namespace_accesses` — treat the published
[provider schema](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/user)
as the source of truth and change them conservatively.

### What a maintainer would need in order to run a real apply test

Three things, all deliberate:

1. **A scratch account you are willing to add and remove users on**, not a shared or production one.
2. **A domain the account controls, whose mail goes somewhere harmless** — a catch-all alias, or a
   provider that accepts and discards. `tests/setup` takes this as `test_email_domain`; its default of
   `example.com` is reserved by [RFC 2606](https://www.rfc-editor.org/rfc/rfc2606) and can never
   receive mail.
3. **A spare user seat.** Accounts cap how many users may exist, and the seat is held until destroy.

With those, an applying test would follow the pattern used elsewhere in this family: one `run` block
creating a single user from `run.setup.user_email`, then later blocks updating that same user's
`account_access` and `namespace_accesses` rather than creating more. Note that `email` forces
replacement, so it must stay constant across the blocks or each one sends a fresh invitation.

This has not been done, and the default configuration must stay unable to do it by accident.

## Running the tests

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Without a key, every run block is skipped — a cheap way to confirm the test files parse:

```text
Failure! 0 passed, 0 failed, N skipped.
```

A syntax or reference error looks different: it names a file and a line rather than reporting a
connection failure.

## Cleaning up leftovers

`scripts/check-orphans.sh` reads the `temporalcloud_users` data source and fails on any address whose
local part starts with `tftest-`. CI runs it after the tests, always, including when they fail.

Because no test creates a user, it should always report zero. It is kept real rather than stubbed out
for two reasons: the data source genuinely can enumerate users, and a maintainer who follows the
section above will need it.

```bash
scripts/check-orphans.sh
```

Anything it reports is a leftover from a hand-run applying test. Confirm each address belongs to the
suite before deleting it — removing a user revokes a real person's access.

The `examples/` directories are not covered by that prefix; they use `developer@example.com` and
`auditor@example.com`. Check for those separately if you have applied an example by hand.

[CONTRIBUTING.md](../CONTRIBUTING.md) explains why the layers are split this way.
