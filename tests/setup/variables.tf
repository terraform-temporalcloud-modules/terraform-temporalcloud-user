variable "test_email_domain" {
  description = "Domain used for generated test addresses. Defaults to `example.com`, which RFC 2606 reserves so it can never receive mail. Change it only to a domain the target account controls, and only when deliberately running an apply test that creates a user"
  type        = string
  default     = "example.com"
}
