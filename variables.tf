variable "create_user" {
  description = "Controls if the user should be created. Set to `false` to disable the module without removing the call. Note that creating a user sends an invitation email to `email`, and destroying one revokes that person's access to the account"
  type        = bool
  default     = true
}

################################################################################
# User
################################################################################

variable "email" {
  description = "Email address of the person to invite. Temporal Cloud sends an invitation to this address on create, and the user remains in a non-`active` state until they accept it. Changing this address replaces the user: the previous address loses access and a new invitation is sent. Required unless `create_user` is `false`"
  type        = string
  default     = ""

  validation {
    condition     = var.email == "" || can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.email))
    error_message = "The email must be a single address of the form local-part@domain.tld."
  }
}

variable "account_access" {
  description = "Account-level role granted to the user: `admin`, `developer`, `read`, `financeadmin` or `metricsread`, matched case-insensitively. `owner` is accepted only when importing an existing owner — it cannot be created, changed or removed without Temporal support. `none` applies only to users whose roles come from SCIM group membership. `admin` and `owner` reach every namespace implicitly, so they cannot be combined with `namespace_accesses`. Required unless `create_user` is `false`"
  type        = string
  default     = ""

  validation {
    condition     = var.account_access == "" || contains(["owner", "admin", "developer", "read", "financeadmin", "metricsread", "none"], lower(var.account_access))
    error_message = "The account_access role must be one of: owner, admin, developer, read, financeadmin, metricsread, none (case-insensitive)."
  }
}

variable "account_access_custom_roles" {
  description = "IDs of custom roles granted in addition to the built-in `account_access` role. Omit rather than passing an empty set"
  type        = set(string)
  default     = null

  validation {
    condition     = try(length(var.account_access_custom_roles) > 0, true)
    error_message = "Empty custom role sets are not accepted by the provider. Omit the variable instead."
  }
}

variable "namespace_accesses" {
  description = "Per-namespace grants, as a set of `namespace_id` and `permission` pairs. `permission` is `admin`, `write` or `read`, matched case-insensitively. This set is the user's complete namespace access map, so removing an entry revokes that access. Omit rather than passing an empty set, and omit entirely when `account_access` is `admin` or `owner`"
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
  description = "Create and delete timeouts, as duration strings such as `30s` or `2h45m`"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}
