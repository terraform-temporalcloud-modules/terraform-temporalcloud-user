# Read-only Temporal Cloud user example

Configuration in this directory invites a user who can inspect one existing namespace and change
nothing anywhere: `account_access = "read"` plus a single `read` namespace grant. This is the shape
most audit, support and on-call-observer accounts should take.

Nothing but the user is created — the namespace is referenced by ID, which is the usual case once an
account is established. See [complete](../complete) for an example that creates its own supporting
resources.

## This example emails a person

`terraform apply` sends an invitation to `var.email`, and `terraform destroy` revokes that person's
access to the account. The default is `auditor@example.com`:
[RFC 2606](https://www.rfc-editor.org/rfc/rfc2606) reserves `example.com` so it can never receive mail,
which means the example as written invites nobody. **Override it only when you intend to send a real
invitation.**

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan  -var 'namespace_id=orders-prod.a1b2c'
terraform apply -var 'namespace_id=orders-prod.a1b2c'
```

`namespace_id` is the fully qualified `<namespace>.<account_id>` form, not the bare namespace name. The
`temporalcloud_namespaces` data source lists the ones on your account.

Note that this example consumes a user seat on the account. Run `terraform destroy` when you no longer
need it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_user"></a> [user](#module\_user) | terraform-temporalcloud-modules/user/temporalcloud | ~> 1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_email"></a> [email](#input\_email) | Email address to invite. Temporal Cloud sends a real invitation to this address on apply | `string` | `"auditor@example.com"` | no |
| <a name="input_namespace_id"></a> [namespace\_id](#input\_namespace\_id) | ID of an existing namespace to grant read access to, in the form `<namespace>.<account_id>` | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_user_id"></a> [user\_id](#output\_user\_id) | The unique identifier of the user |
| <a name="output_user_namespace_accesses"></a> [user\_namespace\_accesses](#output\_user\_namespace\_accesses) | The user's complete namespace access map |
| <a name="output_user_state"></a> [user\_state](#output\_user\_state) | Whether the invitation has been accepted — `active` once it has |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
