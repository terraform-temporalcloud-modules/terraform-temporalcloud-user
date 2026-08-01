terraform {
  required_version = ">= 1.5.7"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    # Configuration comes from the provider block in the calling .tftest.hcl
    # file. Declared explicitly because without this entry Terraform resolves the
    # name to hashicorp/temporalcloud and fails on the type mismatch.
    temporalcloud = {
      source  = "temporalio/temporalcloud"
      version = ">= 1.6.0"
    }
  }
}
