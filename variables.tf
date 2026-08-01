variable "create_user" {
  description = "Controls if the user should be created. Set to `false` to disable the module without removing the call — `email` and `account_access` are required by Terraform either way, so pass `\"\"` for both when the module is switched off. Note that creating a user sends an invitation email to `email`, and destroying one revokes that person's access to the account"
  type        = bool
  default     = true
}

################################################################################
# User
################################################################################

variable "email" {
  description = "Email address of the person to invite. Temporal Cloud sends an invitation to this address on create, and the person has to accept it before they can sign in. Changing this address replaces the user: the previous address loses access and a new invitation is sent. Pass `\"\"` when `create_user` is `false`, where no user is created and the value goes unused"
  type        = string

  validation {
    condition     = var.email == "" || can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.email))
    error_message = "The email must be a single address of the form local-part@domain.tld."
  }
}

variable "account_access" {
  description = "Account-level role granted to the user: `admin`, `developer`, `read`, `financeadmin` or `metricsread`, matched case-insensitively. `owner` is accepted only when importing an existing owner — it cannot be created, changed or removed without Temporal support. Those six are the whole set: `none` is valid on `temporalcloud_group_access` but not on a user, though a SCIM-managed user can read back as `none`. `admin` and `owner` reach every namespace implicitly, so they cannot be combined with `namespace_accesses`. Pass `\"\"` when `create_user` is `false`, where no user is created and the value goes unused"
  type        = string

  # These six are exactly what the provider's own schema validator accepts.
  # `none` is reported back for SCIM-managed users whose role comes from group
  # membership, but it cannot be set here — the provider rejects it.
  validation {
    condition     = var.account_access == "" || contains(["owner", "admin", "developer", "read", "financeadmin", "metricsread"], lower(var.account_access))
    error_message = "The account_access role must be one of: owner, admin, developer, read, financeadmin, metricsread (case-insensitive)."
  }
}

variable "account_access_custom_roles" {
  description = "Optional. IDs of custom roles granted in addition to the built-in `account_access` role; left out, the user holds only that built-in role. A principal may be assigned at most 10 custom roles. Omit rather than passing an empty set"
  type        = set(string)
  default     = null

  validation {
    condition     = try(length(var.account_access_custom_roles) > 0, true)
    error_message = "Empty custom role sets are not accepted by the provider. Omit the variable instead."
  }
}

variable "namespace_accesses" {
  description = "Optional, and rejected outright when `account_access` is `admin` or `owner` — those roles reach every namespace implicitly. Per-namespace grants, as a set of entries whose `namespace_id` and `permission` are both required. `permission` is `admin`, `write` or `read`, matched case-insensitively. Other account roles carry no automatic namespace access — a `developer` gets it only on namespaces they create themselves — so a user who needs a namespace needs an entry here or a group grant. This set is the user's complete namespace access map, so removing an entry revokes that access. Omit rather than passing an empty set"
  type = set(object({
    namespace_id = string
    permission   = string
  }))
  default = null

  validation {
    condition     = try(length(var.namespace_accesses) > 0, true)
    error_message = "Empty namespace access sets are not accepted by the provider. Omit the variable instead."
  }

  # try() covers the null variable: the comprehension raises before alltrue() is
  # reached, rather than short-circuiting.
  validation {
    condition = try(alltrue([
      for access in var.namespace_accesses :
      contains(["admin", "write", "read"], lower(access.permission))
    ]), true)
    error_message = "Namespace access permissions must be one of: admin, write, read (case-insensitive)."
  }
}

variable "timeouts" {
  description = "Optional. Create and delete timeouts, as duration strings such as `30s` or `2h45m`. Left out, the provider's own defaults apply"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}
