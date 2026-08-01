# Complete Temporal Cloud user example

Configuration in this directory invites a Temporal Cloud user with a built-in account role, an
additional custom role, per-namespace grants and explicit timeouts. It also creates the namespace and
the custom role those grants point at, so it runs standalone.

## This example emails a person

`terraform apply` sends an invitation to the address in `local.email`, and `terraform destroy` revokes
that person's access to the account. The address used here is `developer@example.com`:
[RFC 2606](https://www.rfc-editor.org/rfc/rfc2606) reserves `example.com` so it can never receive mail,
which means the example as written invites nobody. **Change it only when you intend to send a real
invitation.**

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan
terraform apply
```

Note that this example creates resources which cost money, and adds a user to the account's user
limit. Run `terraform destroy` when you no longer need them.

Whether the invited person has accepted is not reported through `user_state`, which tracks the
provisioning of the user record rather than the invitation. Applying again reports no changes either
way — acceptance happens outside Terraform.

The namespace region is read from the `temporalcloud_regions` data source rather than hardcoded,
because the regions an account may use are a subset of the published list.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_user"></a> [user](#module\_user) | terraform-temporalcloud-modules/user/temporalcloud | ~> 2.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_custom_role.billing_reader](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/custom_role) | resource |
| [temporalcloud_namespace.orders](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/namespace) | resource |
| [temporalcloud_regions.available](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/data-sources/regions) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_user_account_access_custom_roles"></a> [user\_account\_access\_custom\_roles](#output\_user\_account\_access\_custom\_roles) | Custom roles granted on top of the built-in account role |
| <a name="output_user_email"></a> [user\_email](#output\_user\_email) | The address the invitation was sent to |
| <a name="output_user_id"></a> [user\_id](#output\_user\_id) | The unique identifier of the user |
| <a name="output_user_namespace_accesses"></a> [user\_namespace\_accesses](#output\_user\_namespace\_accesses) | The user's complete namespace access map |
| <a name="output_user_state"></a> [user\_state](#output\_user\_state) | The provisioning state of the user record — not a signal that the invitation was accepted |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
