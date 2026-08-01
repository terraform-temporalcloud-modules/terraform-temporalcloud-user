# Contributing

## Prerequisites

```bash
brew install pre-commit terraform-docs
brew install terraform-linters/tap/tflint
pre-commit install
```

Local tool versions must match the pins in
[`.github/workflows/pre-commit.yml`](.github/workflows/pre-commit.yml). terraform-docs changed its
markdown table style after v0.20.0, so a mismatch makes CI reject README tables that were generated
correctly on your machine. When you bump one side, bump the other in the same pull request.

## The gate

```bash
pre-commit run -a
```

This is what CI runs: `terraform fmt`, `terraform-docs`, `tflint`, `terraform validate`, plus two local
checks described below. Expect the first run after a change to *modify* files — terraform-docs rewrites
the README tables. Re-run until clean; it should pass twice in a row.

## Test layers

| Path | Runs on | Credentials | Proves |
| --- | --- | --- | --- |
| `examples/*` | every PR | no | The documented usage still type-checks against this code |
| `tests/local/` | every PR | no | Every input and output is still valid |
| `tests/*.tftest.hcl` | on demand, weekly | **yes** | The provider accepts what this module generates |

`terraform validate` is not a test: it never executes anything and never contacts the API.

`terraform plan` is not a usable middle ground for *offline* checking, because the provider
authenticates when it initialises and so needs a real key even for a plan that would create nothing.
It is, however, the ceiling of what this module's apply layer can safely do — see below.

### Why the apply layer creates nothing

Everywhere else in this module family, the apply layer exists because only a real apply catches the
Temporal Cloud API rejecting a configuration that type-checks. That trade does not hold for
`temporalcloud_user`: creating one emails a real person, counts against the account's user limit, and
destroying it revokes that person's access. A weekly unattended job must not do any of those.

So `tests/*.tftest.hcl` is plan-only, apart from a `create_user = false` case that creates nothing by
definition. [`tests/README.md`](tests/README.md) records exactly what is therefore uncovered, and what
a maintainer would need in order to run a real apply test deliberately.

Two practical consequences:

- **`tests/local/` carries more weight here than in the sibling modules.** For every input except
  `create_user` it is the only automated check. Add to it in the same pull request that adds a
  variable.
- **Values are not verified, only shapes.** Role names, custom role IDs and namespace IDs are checked
  by the API on apply and nowhere else. Change them against the published provider schema rather than
  from memory.

### Why examples are validated indirectly

`examples/*` source the **published** module so consumers can copy them verbatim from the Terraform
Registry. Validating them as written would check the last release rather than the working tree, which
would mean a module change and its example update could never land in the same pull request.

[`scripts/validate-examples.sh`](scripts/validate-examples.sh) resolves this: it copies each example to
a temporary directory, rewrites the registry source to a path to the repository root, and validates the
copy. Tracked files are never modified. `terraform_validate` excludes `examples/`, and the
`examples-validate` hook covers them instead.

One consequence: examples are validated only on the maximum supported Terraform version, because the
exclusion also removes them from the minimum-version matrix jobs. The root module and `tests/local/`
are still checked against the minimum, which is what `required_version` asserts.

### Why `wrappers/` is hand-maintained

The upstream `terraform_wrapper_module_for_each` pre-commit hook is not enabled. It hardcodes
`terraform-aws-modules` and `aws` in the source addresses it generates, and it overwrites
`wrappers/README.md` on every run with an Amazon S3 example whose inputs do not exist in this module.
It offers no way to skip that file, so restoring a correct one leaves the gate permanently dirty.

[`scripts/check-wrapper-sync.sh`](scripts/check-wrapper-sync.sh) replaces the one useful thing the hook
did: it fails if a root variable is not passed through `wrappers/main.tf`. When you add a variable to
the root module, add the matching line to the wrapper in the same change.

## Behaviours the module guards against

Each of these is a real Temporal Cloud constraint that a plausible configuration trips over.

1. **`account_access` of `owner` or `admin` cannot carry `namespace_accesses`.** Those roles reach every
   namespace implicitly, and the provider's own schema validator refuses explicit grants for them, so
   the combination never reaches the API. The module repeats the check as a `precondition` so the
   error names the module inputs rather than the resource attribute inside it. It cannot be a
   `variable` validation: cross-variable references in validation conditions need Terraform 1.9, above
   this module's `required_version` floor.
2. **`owner` cannot be created, changed or removed by Terraform.** It is accepted only so an existing
   owner can be imported. Anything else needs Temporal support.
3. **Empty sets are rejected, not treated as "none".** Both `account_access_custom_roles` and
   `namespace_accesses` must be omitted rather than passed as `[]`. The module validates this so the
   error arrives during plan.
4. **`email` forces replacement.** Changing it destroys the user and creates another, which revokes the
   old address and sends a fresh invitation.
5. **`namespace_accesses` is the complete access map**, not a set of additions. Removing an entry
   revokes that access.

When writing assertions, note that outputs wrapped in `try(x, [])` evaluate to a *tuple*, so
`output.user_namespace_accesses == toset([])` is false even against an empty result. Compare with
`length()` and index elementwise instead.

Note also that a `command = plan` run block can only assert on values known at plan time. `user_id` and
`user_state` are assigned by the API and stay unknown, so asserting on them fails the run.

## Running the tests

```bash
export TEMPORAL_CLOUD_API_KEY="<key for a scratch account>"
terraform init
terraform test -verbose
```

Without a key every run block is skipped, which is a cheap way to check that the test files parse:

```text
Failure! 0 passed, 0 failed, N skipped.
```

In CI they run from the **Apply Tests** workflow. Its first step is `scripts/check-api.sh`, a liveness
check that confirms the API answers and the key is accepted, so a credentials problem fails immediately
rather than surfacing later as a plan that would not build.

Apply Tests is chained after Pre-Commit, and Release after Apply Tests, so a merge to main runs:

```text
push to main -> Pre-Commit -> Apply Tests -> Release
```

A release is therefore only cut from code that passed both the static gate and the provider-backed
tests. Any failure in the chain stops it.

Apply Tests never runs on pull requests: forks cannot read secrets. It also runs weekly, and on demand.
Runs are serialized with `cancel-in-progress: false`.

## Pull requests

Titles must be [conventional commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`,
`ci:`, `chore:` — with a capitalised subject. Squash-merge makes the title the commit message, and
semantic-release derives the next version from it, so an invalid title silently breaks versioning. A
workflow enforces this.

`CHANGELOG.md` and tags are generated on merge. Never bump versions by hand.

If CI reports fewer checks than usual, check whether the pull request has merge conflicts: GitHub skips
`pull_request` workflows when it cannot compute a merge ref, with no failed check to show for it.
