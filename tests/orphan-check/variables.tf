variable "test_resource_prefix" {
  description = "Prefix identifying resources created by the test suite — the local part of a generated address, and the name of the throwaway namespace. Must match what tests/setup generates. Anything matching it after a test run has finished is a leftover"
  type        = string
  default     = "yulei-tftest-usr-"
}
