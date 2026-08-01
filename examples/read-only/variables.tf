variable "email" {
  description = "Email address to invite. Temporal Cloud sends a real invitation to this address on apply"
  type        = string
  default     = "auditor@example.com"
}

variable "namespace_id" {
  description = "ID of an existing namespace to grant read access to, in the form `<namespace>.<account_id>`"
  type        = string
}
