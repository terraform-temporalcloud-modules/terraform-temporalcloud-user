# Wrapper for the Temporal Cloud user module

The configuration in `wrappers/` implements the single module wrapper pattern, which allows managing
several copies of this module from one call in places where the native `for_each` on a module block is
not available — most commonly Terragrunt.

This wrapper adds no functionality of its own. Every key under `items` accepts any input the root
module accepts, and `defaults` supplies values shared by all items.

**Each item invites a real person.** An `apply` that adds a key to `items` sends an invitation email;
removing a key revokes that person's access. Review the plan before applying.

Contributors: see [CONTRIBUTING.md](../CONTRIBUTING.md) for how these files are maintained.

## Usage with Terraform

```hcl
module "users" {
  source = "terraform-temporalcloud-modules/user/temporalcloud//wrappers"

  # Shared by every item unless the item overrides it.
  defaults = {
    account_access = "read"
  }

  items = {
    ana = {
      email = "ana@example.com"

      namespace_accesses = [
        {
          namespace_id = temporalcloud_namespace.orders.id
          permission   = "write"
        },
      ]
    }

    ben = {
      email          = "ben@example.com"
      account_access = "developer" # overrides the default above
    }

    # Account admins reach every namespace implicitly, so they must not carry
    # namespace_accesses.
    cass = {
      email          = "cass@example.com"
      account_access = "admin"
    }
  }
}
```

Outputs are keyed by the same map keys:

```hcl
output "ana_user_id" {
  value = module.users.wrapper["ana"].user_id
}

output "invited_addresses" {
  value = [for key, user in module.users.wrapper : user.user_email]
}
```

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-temporalcloud-modules/user/temporalcloud//wrappers?version=1.0.0"
  # Alternative source:
  # source = "git::git@github.com:terraform-temporalcloud-modules/terraform-temporalcloud-user.git//wrappers?ref=v1.0.0"
}

inputs = {
  defaults = {
    account_access = "read"
  }

  items = {
    ana = { email = "ana@example.com" }
    ben = { email = "ben@example.com", account_access = "developer" }
  }
}
```

Pin `?version=` / `?ref=` to a released tag rather than a branch, so a wrapper upgrade is a deliberate
change.

## Inputs

| Name | Description | Type | Default |
| ---- | ----------- | ---- | ------- |
| `defaults` | Default values applied to every user in `items`, unless that item overrides them | `any` | `{}` |
| `items` | Map of users to invite; each key becomes an instance of the module | `any` | `{}` |

## Outputs

| Name | Description |
| ---- | ----------- |
| `wrapper` | Map of module outputs, keyed by the same keys as `items` |
