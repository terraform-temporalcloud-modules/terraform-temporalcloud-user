# Temporal Cloud User Terraform module

[![CI](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/pre-commit.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/pre-commit.yml?query=branch%3Amain)
[![Apply Tests](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/test.yml?query=branch%3Amain)

Terraform module which manages a [Temporal Cloud](https://temporal.io/cloud) user: their account-level
role, any custom roles, and their per-namespace permissions.

## This module invites a real person

**`terraform apply` on this module sends an invitation email.** That is not a metaphor for creating a
record: Temporal Cloud mails the address in `email` a link, and
[the person has to click it](https://docs.temporal.io/cloud/users) and sign up before they can sign in.

Three consequences that make this module behave unlike most Terraform resources:

- **Apply has a side effect outside your infrastructure.** Someone receives mail. A misspelled address
  invites a stranger, or nobody. Re-running `apply` will not un-send it.
- **`terraform destroy` revokes a real person's access.** Removing a `module` block or a key from a
  wrapper's `items` map takes away that person's ability to sign in to the account. Read the plan.
- **Acceptance happens outside Terraform.** `user_state` is the provisioning state of the user
  *record* — the generic Temporal Cloud resource lifecycle, the same enum namespaces and groups use.
  It is not documented as a signal of whether the invitation was accepted, so do not treat it as one.
  Check the Temporal Cloud UI or `tcld user` for that.

Changing `email` on an existing user **replaces** it: the previous address loses access and a fresh
invitation goes to the new one. Renaming a person's address is a destroy-and-invite, not an update.

## When to use this module — and when not to

**If your account has SCIM, this is probably not the module you want for day-to-day access.** SCIM
provisions users and their group memberships from your identity provider, so managing the same people
here means two systems writing the same records.

What SCIM does *not* do is assign permissions. Temporal Cloud's
[SCIM documentation](https://docs.temporal.io/cloud/scim) is explicit that roles are configured
separately after a group syncs. So the division that works is:

| Concern | Owned by |
| --- | --- |
| Authentication — signing in | [SAML SSO](https://docs.temporal.io/cloud/saml) |
| Which people exist, and their group membership | SCIM, from your identity provider |
| **What a group is allowed to do** | [the `group` module](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-group) |
| Machine access for workers and CI | [the `service-account` module](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-service-account) — never SCIM |

With SCIM in place, grant access to groups rather than to people: point the `group` module at a
SCIM-provisioned group with `create_group = false` and manage its `account_access` and
`namespace_accesses`. Individuals then inherit permissions from membership, and an account role of
`none` on a user is valid precisely to support that pattern.

**Use this module when:**

- **Your account has no SCIM.** SAML and SCIM are both paid features, so plenty of accounts manage
  users directly — in which case this is the only way to keep them in version control.
- **Break-glass access.** An administrator deliberately outside the corporate identity provider, so an
  SSO outage does not lock you out of the control plane.
- **People who are not in the directory** — a contractor, a partner, a vendor.
- **A one-off exception.** SCIM maps groups to roles. One person needing read on one namespace, without
  inventing a directory group for them, is a per-user grant.

**Do not use this module for workers, CI, or any automated client.** Those authenticate with an API key
issued to a service account, which is a different resource and never a user.

## Requirements

The `temporalcloud` provider authenticates with an API key, read from the `TEMPORAL_CLOUD_API_KEY`
environment variable:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"
```

The provider authenticates when it initialises, so a key is needed even for a `terraform plan` that
would create nothing. Keep the key out of version control — an untracked `.env` file rather than a
committed `.tfvars`.

Each user counts towards the account's user limit — [300 by
default](https://docs.temporal.io/cloud/limits) — from the moment they are invited until the resource
is destroyed.

## Usage

### A developer with access to specific namespaces

```hcl
module "user" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 1.0"

  email          = "ana@example.com"
  account_access = "developer"

  # This set is the user's COMPLETE namespace access map. Removing an entry
  # revokes that access on the next apply.
  namespace_accesses = [
    {
      namespace_id = module.orders_namespace.namespace_id
      permission   = "write"
    },
    {
      namespace_id = module.payments_namespace.namespace_id
      permission   = "read"
    },
  ]
}
```

### A read-only user

```hcl
module "auditor" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 1.0"

  email          = "auditor@example.com"
  account_access = "read"

  namespace_accesses = [
    {
      namespace_id = module.orders_namespace.namespace_id
      permission   = "read"
    },
  ]
}
```

### An account admin

Admins reach every namespace implicitly, so they take **no** `namespace_accesses` at all:

```hcl
module "platform_admin" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 1.0"

  email          = "platform@example.com"
  account_access = "admin"
}
```

### Adding a custom role

Custom roles stack on top of the built-in `account_access` role rather than replacing it. A single
principal can hold [at most 10](https://docs.temporal.io/cloud/limits):

```hcl
module "finance_viewer" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud"
  version = "~> 1.0"

  email                       = "finance@example.com"
  account_access              = "read"
  account_access_custom_roles = [temporalcloud_custom_role.billing_reader.id]
}
```

## Choosing an account role

`account_access` is the user's account-wide role. It is required, and it interacts with
`namespace_accesses` in ways worth knowing before you plan:

| Role | Namespace grants | Notes |
| --- | --- | --- |
| `owner` | not allowed | Import only. Cannot be created, changed or removed without Temporal support |
| `admin` | **not allowed** | Reaches every namespace implicitly |
| `developer` | expected | The usual choice for someone who needs specific namespaces |
| `read` | expected | Account-wide read; still needs grants to see workflows in a namespace |
| `financeadmin` | expected | Billing administration |
| `metricsread` | expected | Metrics endpoint access |

Values are matched case-insensitively. These six are the whole set the provider accepts. A
SCIM-managed user whose role comes from group membership reads back as `none`, but `none` cannot be
*set* — the provider rejects it in configuration, so this module does not accept it either.

The vocabulary is not shared with groups: `temporalcloud_group_access` accepts `none` and rejects
`financeadmin` and `metricsread`, which is the mirror image of the list above.

Combining `admin` or `owner` with `namespace_accesses` is refused during plan:

```text
Error: Resource precondition failed

namespace_accesses cannot be combined with an account_access of owner or admin:
those roles already have access to every namespace.
```

The provider enforces the same rule itself (`Users with account_access roles of owner or admin cannot
have namespace accesses`), so neither reaches the API. The module's precondition exists only to point
at the module inputs you wrote rather than at the resource attribute inside it.

## Notes

Behaviours worth knowing before you plan:

- **Empty sets are rejected, not treated as "no access".** Both `account_access_custom_roles` and
  `namespace_accesses` must be omitted rather than passed as `[]`. The module validates this so the
  error arrives during plan rather than from the API.
- **`namespace_accesses` is the complete map, not a set of additions.** Anything granted outside
  Terraform is removed on the next apply, and removing an entry revokes that access.
- **`namespace_id` is the fully qualified `<namespace>.<account_id>` form**, not the bare namespace
  name. That is what the namespace module's `namespace_id` output and the `temporalcloud_namespaces`
  data source both return.
- **Importing an existing user takes their ID, not their email.** `terraform import` against the user
  ID adopts a person who already accepted an invitation, which is the right way to bring an existing
  team under Terraform without re-inviting anyone.
- **Group membership is managed elsewhere.** This module owns the user and their direct grants;
  `temporalcloud_group_members` belongs to the group module and references `user_id`.

## Examples

- [complete](examples/complete) — every input, with the namespace and custom role the grants point at
- [read-only](examples/read-only) — the narrowest useful grant, against an existing namespace

Both examples default to addresses on `example.com`, which
[RFC 2606](https://www.rfc-editor.org/rfc/rfc2606) reserves so it can never receive mail. They invite
nobody until you change that.

## Managing several users

The [`wrappers`](wrappers) submodule creates many users from one call, for use with Terragrunt or
anywhere a `for_each` on the module block is awkward:

```hcl
module "users" {
  source  = "terraform-temporalcloud-modules/user/temporalcloud//wrappers"
  version = "~> 1.0"

  defaults = {
    account_access = "read"
  }

  items = {
    ana = { email = "ana@example.com", account_access = "developer" }
    ben = { email = "ben@example.com" }
  }
}
```

Each key is one invitation, and removing a key revokes that person's access.

## Which inputs are required

`email` and `account_access` are required, and the generated **Inputs** table below says so — they
carry no default because the provider marks both attributes required. What follows is what the table
cannot express.

### Switching the module off still needs both

`create_user = false` creates no user, but Terraform demands a value for a variable without a default
regardless of whether the resource it feeds exists. Pass empty strings:

```hcl
module "user" {
  # source and version as above

  create_user = false

  email          = ""
  account_access = ""
}
```

Neither value reaches Temporal Cloud — the resource is counted out before they are used.

### Conditionally required

- **`namespace_accesses` must be omitted when `account_access` is `owner` or `admin`.** Both roles
  hold Namespace Admin on every namespace already. The provider enforces this in its own schema
  validator — `Users with account_access roles of owner or admin cannot have namespace accesses.
  Remove the namespace_accesses attribute.` — and this module repeats it as a precondition so the
  message names the module input rather than the resource attribute inside it.
- **Every other role needs `namespace_accesses` to reach a namespace at all.** Account-level roles do
  not govern what happens inside a namespace: `read`, `financeadmin` and `metricsread` carry no
  namespace access, and `developer` receives Namespace Admin only on namespaces they create themselves. See
  [Namespace-level permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions#namespace-level-permissions).
  Without an entry here — or membership of a group that has one — the user can sign in but cannot see
  a namespace's workflows.
- **Both keys of every `namespace_accesses` entry are required.** `namespace_id` and `permission` are
  required in the provider schema and in this module's object type, which the generated table cannot
  show: it lists the variable, not the keys inside it. Omitting one fails at validate with
  `element 0: attribute "permission" is required.`
- **Empty sets are not the same as omission.** `namespace_accesses` and `account_access_custom_roles`
  are each rejected as `[]`, by this module and by the provider. Omit them.

The `owner`/`admin` rule is the one of these that `terraform validate` does not catch: it compares two
variables, so it lives in a resource precondition and is evaluated at plan. The rest are `variable`
validations and fail at validate, without credentials.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_temporalcloud"></a> [temporalcloud](#provider\_temporalcloud) | >= 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_user.this](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_access"></a> [account\_access](#input\_account\_access) | Account-level role granted to the user: `admin`, `developer`, `read`, `financeadmin` or `metricsread`, matched case-insensitively. `owner` is accepted only when importing an existing owner — it cannot be created, changed or removed without Temporal support. Those six are the whole set: `none` is valid on `temporalcloud_group_access` but not on a user, though a SCIM-managed user can read back as `none`. `admin` and `owner` reach every namespace implicitly, so they cannot be combined with `namespace_accesses`. Pass `""` when `create_user` is `false`, where no user is created and the value goes unused | `string` | n/a | yes |
| <a name="input_account_access_custom_roles"></a> [account\_access\_custom\_roles](#input\_account\_access\_custom\_roles) | Optional. IDs of custom roles granted in addition to the built-in `account_access` role; left out, the user holds only that built-in role. A principal may be assigned at most 10 custom roles. Omit rather than passing an empty set | `set(string)` | `null` | no |
| <a name="input_create_user"></a> [create\_user](#input\_create\_user) | Controls if the user should be created. Set to `false` to disable the module without removing the call — `email` and `account_access` are required by Terraform either way, so pass `""` for both when the module is switched off. Note that creating a user sends an invitation email to `email`, and destroying one revokes that person's access to the account | `bool` | `true` | no |
| <a name="input_email"></a> [email](#input\_email) | Email address of the person to invite. Temporal Cloud sends an invitation to this address on create, and the person has to accept it before they can sign in. Changing this address replaces the user: the previous address loses access and a new invitation is sent. Pass `""` when `create_user` is `false`, where no user is created and the value goes unused | `string` | n/a | yes |
| <a name="input_namespace_accesses"></a> [namespace\_accesses](#input\_namespace\_accesses) | Optional, and rejected outright when `account_access` is `admin` or `owner` — those roles reach every namespace implicitly. Per-namespace grants, as a set of entries whose `namespace_id` and `permission` are both required. `permission` is `admin`, `write` or `read`, matched case-insensitively. Other account roles carry no automatic namespace access — a `developer` gets it only on namespaces they create themselves — so a user who needs a namespace needs an entry here or a group grant. This set is the user's complete namespace access map, so removing an entry revokes that access. Omit rather than passing an empty set | <pre>set(object({<br/>    namespace_id = string<br/>    permission   = string<br/>  }))</pre> | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional. Create and delete timeouts, as duration strings such as `30s` or `2h45m`. Left out, the provider's own defaults apply | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_user_account_access"></a> [user\_account\_access](#output\_user\_account\_access) | The account-level role granted to the user |
| <a name="output_user_account_access_custom_roles"></a> [user\_account\_access\_custom\_roles](#output\_user\_account\_access\_custom\_roles) | IDs of the custom roles granted to the user in addition to the built-in account role. Empty when none are assigned |
| <a name="output_user_email"></a> [user\_email](#output\_user\_email) | The email address the invitation was sent to |
| <a name="output_user_id"></a> [user\_id](#output\_user\_id) | The unique identifier of the user. This is the ID other resources reference, for example `temporalcloud_group_members.users` |
| <a name="output_user_namespace_accesses"></a> [user\_namespace\_accesses](#output\_user\_namespace\_accesses) | The user's complete namespace access map, as `namespace_id` and `permission` pairs. Empty for account roles that reach every namespace implicitly |
| <a name="output_user_state"></a> [user\_state](#output\_user\_state) | The provisioning state of the user record, as reported by Temporal Cloud: one of `activating`, `active`, `updating`, `deleting`, `deleted`, `suspended`, `expired`, or the `activationfailed`, `updatefailed` and `deletefailed` error states. This is the lifecycle of the record, not a signal of whether the person has accepted their invitation — check the Temporal Cloud UI or `tcld user` for that |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, how the test layers are arranged,
and how the apply tests create real users without ever mailing a person.

## License

Apache-2.0 licensed. See [LICENSE](LICENSE).
