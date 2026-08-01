variable "test_email_prefix" {
  description = "Local-part prefix identifying users created by the test suite. Anything matching it after a test run has finished is a leftover"
  type        = string
  default     = "tftest-"
}
