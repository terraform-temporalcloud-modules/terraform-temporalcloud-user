# Temporal Cloud User Terraform module

[![CI](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/pre-commit.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/pre-commit.yml?query=branch%3Amain)
[![Apply Tests](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/actions/workflows/test.yml?query=branch%3Amain)

Terraform module which manages a [Temporal Cloud](https://temporal.io/cloud) user: their account-level
role, any custom roles, and their per-namespace permissions.

## This module invites a real person

**`terraform apply` on this module sends an invitation email.** That is not a metaphor for creating a
record: Temporal Cloud mails the address in `email` a link, and the person has to click it and sign up
before the user is usable. Until they do, `user_state` reports `activating` rather than `active`.

Three consequences that make this module behave unlike most Terraform resources:

- **Apply has a side effect outside your infrastructure.** Someone receives mail. A misspelled address
  invites a stranger, or nobody. Re-running `apply` will not un-send it.
- **`terraform destroy` revokes a real person's access.** Removing a `module` block or a key from a
  wrapper's `items` map takes away that person's ability to sign in to the account. Read the plan.
- **Acceptance happens outside Terraform, so `user_state` changes on its own.** The value is read on
  refresh; Terraform never plans a change to bring it back. Do not write logic that waits for it.

Changing `email` on an existing user **replaces** it: the previous address loses access and a fresh
invitation goes to the new one. Renaming a person's address is a destroy-and-invite, not an update.

## Requirements

The `temporalcloud` provider authenticates with an API key, read from the `TEMPORAL_CLOUD_API_KEY`
environment variable:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"
```

The provider authenticates when it initialises, so a key is needed even for a `terraform plan` that
would create nothing. Keep the key out of version control — an untracked `.env` file rather than a
committed `.tfvars`.

Inviting a user also consumes a user seat on the account, which is held until the resource is
destroyed.

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

Custom roles stack on top of the built-in `account_access` role rather than replacing it:

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
| `none` | expected | Only for users whose roles come from SCIM group membership |

Values are matched case-insensitively.

Combining `admin` or `owner` with `namespace_accesses` is refused by the module during plan:

```text
Error: Resource precondition failed

namespace_accesses cannot be combined with an account_access of owner or admin:
those roles already have access to every namespace.
```

Without that guard the same mistake reaches the API and fails partway through an apply — after the
invitation has already been sent.

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
| <a name="input_account_access"></a> [account\_access](#input\_account\_access) | Account-level role granted to the user: `admin`, `developer`, `read`, `financeadmin` or `metricsread`, matched case-insensitively. `owner` is accepted only when importing an existing owner — it cannot be created, changed or removed without Temporal support. `none` applies only to users whose roles come from SCIM group membership. `admin` and `owner` reach every namespace implicitly, so they cannot be combined with `namespace_accesses`. Required unless `create_user` is `false` | `string` | `""` | no |
| <a name="input_account_access_custom_roles"></a> [account\_access\_custom\_roles](#input\_account\_access\_custom\_roles) | IDs of custom roles granted in addition to the built-in `account_access` role. Omit rather than passing an empty set | `set(string)` | `null` | no |
| <a name="input_create_user"></a> [create\_user](#input\_create\_user) | Controls if the user should be created. Set to `false` to disable the module without removing the call. Note that creating a user sends an invitation email to `email`, and destroying one revokes that person's access to the account | `bool` | `true` | no |
| <a name="input_email"></a> [email](#input\_email) | Email address of the person to invite. Temporal Cloud sends an invitation to this address on create, and the user remains in a non-`active` state until they accept it. Changing this address replaces the user: the previous address loses access and a new invitation is sent. Required unless `create_user` is `false` | `string` | `""` | no |
| <a name="input_namespace_accesses"></a> [namespace\_accesses](#input\_namespace\_accesses) | Per-namespace grants, as a set of `namespace_id` and `permission` pairs. `permission` is `admin`, `write` or `read`, matched case-insensitively. This set is the user's complete namespace access map, so removing an entry revokes that access. Omit rather than passing an empty set, and omit entirely when `account_access` is `admin` or `owner` | <pre>set(object({<br/>    namespace_id = string<br/>    permission   = string<br/>  }))</pre> | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create and delete timeouts, as duration strings such as `30s` or `2h45m` | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_user_account_access"></a> [user\_account\_access](#output\_user\_account\_access) | The account-level role granted to the user |
| <a name="output_user_account_access_custom_roles"></a> [user\_account\_access\_custom\_roles](#output\_user\_account\_access\_custom\_roles) | IDs of the custom roles granted to the user in addition to the built-in account role. Empty when none are assigned |
| <a name="output_user_email"></a> [user\_email](#output\_user\_email) | The email address the invitation was sent to |
| <a name="output_user_id"></a> [user\_id](#output\_user\_id) | The unique identifier of the user. This is the ID other resources reference, for example `temporalcloud_group_members.users` |
| <a name="output_user_namespace_accesses"></a> [user\_namespace\_accesses](#output\_user\_namespace\_accesses) | The user's complete namespace access map, as `namespace_id` and `permission` pairs. Empty for account roles that reach every namespace implicitly |
| <a name="output_user_state"></a> [user\_state](#output\_user\_state) | The current state of the user, as reported by Temporal Cloud. `active` means the person has accepted their invitation and the account is usable; while an invitation is outstanding the user reports `activating` instead, and `expired` once an unaccepted invitation lapses. Other values are `updating`, `suspended`, `deleting`, `deleted`, and the `activationfailed`, `updatefailed` and `deletefailed` error states |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, how the test layers are arranged,
and why the apply layer here deliberately creates nothing.

## License

Apache-2.0 licensed. See [LICENSE](LICENSE).
