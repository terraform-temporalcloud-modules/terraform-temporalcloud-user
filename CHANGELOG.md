# Changelog

All notable changes to this project will be documented in this file.

## [2.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v2.0.1...v2.0.2) (2026-08-03)

### Tests

* Coalesce null data source lists in the orphan check ([#1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/issues/1)) ([8ffa4d5](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/8ffa4d52c9da5bc76f47c3ab5270c031f587aa4b))

## [2.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v2.0.0...v2.0.1) (2026-08-01)

### Documentation

* Pin the examples to v2 ([316c305](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/316c305251db70a0a7303f9a737aa87fb5520e05))

## [2.0.0](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v1.0.3...v2.0.0) (2026-08-01)

### ⚠ BREAKING CHANGES

* email and account_access no longer have defaults. A module call
that sets create_user = false must now pass them explicitly.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

### Features

* Require the inputs the provider requires ([78498d1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/78498d1131e8c2815a5b680148a58bb5b942ee6a))

## [1.0.3](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v1.0.2...v1.0.3) (2026-08-01)

### Documentation

* Trim the validate explanation to what a consumer needs ([8bef7ab](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/8bef7ab267f969cd27ed766f1c3612ce8b0f5903))

## [1.0.2](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v1.0.1...v1.0.2) (2026-08-01)

## [1.0.1](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/compare/v1.0.0...v1.0.1) (2026-08-01)

### Bug Fixes

* reject account_access "none" and stop treating user_state as an invitation signal ([2affc48](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/2affc48f49c9df9172a2a12d811b50406b1c214b))

## 1.0.0 (2026-08-01)

### Features

* Initial user module ([ef75e19](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-user/commit/ef75e19003f33c886b93e496a3dbc6b5a0c5682e))
