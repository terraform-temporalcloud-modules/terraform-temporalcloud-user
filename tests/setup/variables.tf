variable "test_email_domain" {
  description = "Domain used for generated test addresses. Defaults to `example.com`, which RFC 2606 reserves so it can never receive mail. The applying tests assert this value before they create anything, so repointing it at a deliverable domain fails the run rather than mailing a stranger"
  type        = string
  default     = "example.com"
}

variable "create_namespace_fixture" {
  description = "Controls if the throwaway namespace is created. Off by default so only the run block that needs a real `namespace_id` pays for it, and so a namespace quota or a region entitlement cannot skip the coverage that runs before it"
  type        = bool
  default     = false
}
