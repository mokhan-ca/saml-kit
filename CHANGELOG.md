# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.2](https://github.com/mokhan-ca/saml-kit/compare/v1.5.1...v1.5.2) (2026-11-25)


### Bug Fixes

* decrypt a copy of the document ([85d58df](https://github.com/mokhan-ca/saml-kit/commit/85d58df05790895f04cfd9deba84467ba8b20a8b))
* link the gem to its repository and changelog ([354e379](https://github.com/mokhan-ca/saml-kit/commit/354e379f9337a72e217fb866000578d57cb3c41d))
* read the name id of a refused document ([ad135e2](https://github.com/mokhan-ca/saml-kit/commit/ad135e2fc4363cdd12fb72e24d6659783f72b117))
* read to_h from the nokogiri tree ([e09dae7](https://github.com/mokhan-ca/saml-kit/commit/e09dae7bfa43cc417dcf764046cb291cbb66e875))
* read xml of any encoding as utf-8 ([52bce6b](https://github.com/mokhan-ca/saml-kit/commit/52bce6be2579064c3b483fedb93e668b7e08a83e))
* report an unreadable certificate as missing ([ab68ac9](https://github.com/mokhan-ca/saml-kit/commit/ab68ac9fd3ccaec67c8ac77ef8de0b27cea08106))
* require a registered key when a Response is signed ([72f79de](https://github.com/mokhan-ca/saml-kit/commit/72f79de169c14febe07549881a655f46c3acaa9c))
* require an identity provider to issue a Response ([3a8c0c1](https://github.com/mokhan-ca/saml-kit/commit/3a8c0c126aff30c1a9911e835ca1c6e59d2d38ca))
* require nokogiri 1.19.1 ([46c101b](https://github.com/mokhan-ca/saml-kit/commit/46c101b40cfcad5e1cfd98a6b2f202a74ba90245))
* require the same issuer on a Response and its Assertion ([a9236ec](https://github.com/mokhan-ca/saml-kit/commit/a9236ec85430864c3910606ded5b6f10a179cad2))
* require valid utf-8 in a decrypted Assertion ([a79113a](https://github.com/mokhan-ca/saml-kit/commit/a79113a382a9ba2ed0bd249d0eed2a6ef271d3dc))
* require well formed xml without a document type ([69aa755](https://github.com/mokhan-ca/saml-kit/commit/69aa7550a6128f769cc4f7882c5631251c77f3e4))
* require xml-kit 0.7 ([7eb7705](https://github.com/mokhan-ca/saml-kit/commit/7eb77058bf14712b5b9982c7df611c01186c8acf))
* return both descriptors from CompositeMetadata ([8f4dcdc](https://github.com/mokhan-ca/saml-kit/commit/8f4dcdc1d55e3c458f1403c31cf9e132d57b4041))
* translate each error of a refused document ([bae0d41](https://github.com/mokhan-ca/saml-kit/commit/bae0d4110950c986d64288aa697e79f8a7893cc6))

## [1.5.1] - 2026-08-18
### Fixed
- Compile the SAML XSDs without `Dir.chdir`. Schema compilation ran inside a
  `Dir.chdir` block, which mutates process global state, so two threads
  validating a document at the same time could raise `conflicting chdir during
  another chdir block`. Each schema is now parsed as a document carrying its own
  path, so its relative imports resolve without changing the working directory.
- Compile each XSD once instead of on every `valid?` call.

## [1.5.0] - 2026-08-17
### Security
- Reject a `Response` or `Assertion` that carries no signature. A registered
  issuer was previously enough to make an unsigned document valid, so anyone
  who could reach the assertion consumer service could forge an assertion for
  any user. (GHSA-hx7c-98jm-7r55)
- Require an xml signature to reference the element it is attached to. A
  signature was verified without checking which element it covered, so a valid
  signature could be copied onto a forged element with the element it really
  covered hidden in `saml:Advice` or `ds:Object`. (GHSA-q726-45rx-qvrw)

### Changed
This release rejects documents that 1.4.1 accepted. Each case below was
exploitable or is a side effect of closing one that was.

- An unsigned `Response` or `Assertion` is now invalid, even when its issuer is
  registered. Set `configuration.signature_required = false` to restore the old
  behaviour while an identity provider is being fixed; doing so accepts forged
  assertions. Signing only the `Assertion` is still accepted, as is an unsigned
  `AuthnRequest`, `LogoutRequest` or `LogoutResponse`.
- `Response.build` on a `Configuration` with no signing key pair emits an
  unsigned document, which now fails `valid?`. Call
  `generate_key_pair_for(use: :signing)` or `add_key_pair`.
- `Assertion.new` with an unsigned assertion as a `String` is now invalid,
  because a bare assertion is the whole document and nothing else vouches for
  it. Passing the same assertion as a node nested in a `Response` is unchanged.
- A signature whose `ds:Reference` does not resolve to the element it hangs
  off, or resolves to more than one element, adds an error on `:reference`.

### Added
- `Saml::Kit::Configuration#signature_required`, defaulting to `true`.

## [1.4.1] - 2026-08-14
### Changed
- fix: decode encoded signature

## [1.4.0] - 2025-03-26
### Added
- Add support for converting `Assertion` xml to `Saml::Document`

### Removed
- Drop support for ruby 2.7
- Drop support for ruby 3.0

## [1.3.0] - 2022-03-30
### Removed

- Drop support for ruby 2.6
- Drop support for ruby 2.5

### Changed

- fix: upgrade to Ruby 2.7+ `*args` syntax.
- fix: resolve deprecation warnings

## [1.2.0] - 2021-02-04
### Changed
- Use [ActiveModel::Errors#add](https://www.rubydoc.info/docs/rails/ActiveModel%2FErrors:add)
- Update minimum activemodel version to `5.1`.

## [1.1.0] - 2019-04-30
### Added
- Add support for ForceAuthn attribute on AuthnRequest

### Removed
- Drop support for ruby 2.2
- Drop support for ruby 2.3

### Changed
- Rescue from invalid signature validation
- Change minimum ruby version to 2.4
- Change minimum bundler to 2.0

## [1.0.31] - 2019-04-17
### Changed
- Rescue from all decryption errors

## [1.0.30] - 2019-04-07
### Changed
- change xml-kit dependency to minimum 0.3.0
- use `encrypt_data_for` instead of `encryption_for`.

## [1.0.29] - 2018-12-04
### Changed
- change xml-kit dependency to ~> 0.2.

## [1.0.28] - 2018-12-04
### Changed
- Parse attribute arrays from SAML assertion.

## [1.0.27] - 2018-11-08
### Changed
- Evict expired key pairs from configuration.

## [1.0.26] - 2018-10-22
### Changed
- Forward destination, issuer, now, embed\_signature to assertion.

## [1.0.25] - 2018-10-17
### Changed
- Allow multi valued attributes in response assertion.

## [1.0.24] - 2018-09-18
### Added
- Parse ID from assertion.
- Parse version from assertion.
- Parse version from assertion.
- Add missing English translations.

### Changed
- Moved backing fields from response builder to assertion.

## [1.0.23] - 2018-08-23
### Added
- Add NotOnOrAfter attribute to SubjectConfirmationData.

## [1.0.22] - 2018-08-13
### Added
- Allow using a custom NameID Format in Assertion.

## [1.0.21] - 2018-08-13
### Changed
- Use net/hippie instead of net/http.

### Removed
- remove optional NotOnOrAfter attribute from SubjectConfirmationData.

## [1.0.20] - 2018-08-11
### Changed
- Synchronize NotOnOrAfter between AuthnStatement and SubjectConfirmationData.

### Removed
- Removed optional SessionNotOnOrAfter attribute from AuthnStatement.

[Unreleased]: https://github.com/xlgmokha/saml-kit/compare/v1.5.1...HEAD
[1.5.1]: https://github.com/xlgmokha/saml-kit/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/xlgmokha/saml-kit/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/xlgmokha/saml-kit/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/xlgmokha/saml-kit/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/xlgmokha/saml-kit/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/xlgmokha/saml-kit/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/xlgmokha/saml-kit/compare/v1.0.31...v1.1.0
[1.0.31]: https://github.com/xlgmokha/saml-kit/compare/v1.0.30...v1.0.31
[1.0.30]: https://github.com/xlgmokha/saml-kit/compare/v1.0.29...v1.0.30
[1.0.29]: https://github.com/xlgmokha/saml-kit/compare/v1.0.28...v1.0.29
[1.0.28]: https://github.com/xlgmokha/saml-kit/compare/v1.0.27...v1.0.28
[1.0.27]: https://github.com/xlgmokha/saml-kit/compare/v1.0.26...v1.0.27
[1.0.26]: https://github.com/xlgmokha/saml-kit/compare/v1.0.25...v1.0.26
[1.0.25]: https://github.com/xlgmokha/saml-kit/compare/v1.0.24...v1.0.25
[1.0.24]: https://github.com/xlgmokha/saml-kit/compare/v1.0.23...v1.0.24
[1.0.23]: https://github.com/xlgmokha/saml-kit/compare/v1.0.22...v1.0.23
[1.0.22]: https://github.com/xlgmokha/saml-kit/compare/v1.0.21...v1.0.22
[1.0.21]: https://github.com/xlgmokha/saml-kit/compare/v1.0.20...v1.0.21
[1.0.20]: https://github.com/xlgmokha/saml-kit/compare/v1.0.19...v1.0.20
[1.0.19]: https://github.com/xlgmokha/saml-kit/compare/v1.0.18...v1.0.19
[1.0.18]: https://github.com/xlgmokha/saml-kit/compare/v1.0.17...v1.0.18
[1.0.17]: https://github.com/xlgmokha/saml-kit/compare/v1.0.16...v1.0.17
[1.0.16]: https://github.com/xlgmokha/saml-kit/compare/v1.0.15...v1.0.16
[1.0.15]: https://github.com/xlgmokha/saml-kit/compare/v1.0.14...v1.0.15
[1.0.14]: https://github.com/xlgmokha/saml-kit/compare/v1.0.13...v1.0.14
[1.0.13]: https://github.com/xlgmokha/saml-kit/compare/v1.0.12...v1.0.13
[1.0.12]: https://github.com/xlgmokha/saml-kit/compare/v1.0.11...v1.0.12
[1.0.11]: https://github.com/xlgmokha/saml-kit/compare/v1.0.10...v1.0.11
[1.0.10]: https://github.com/xlgmokha/saml-kit/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/xlgmokha/saml-kit/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/xlgmokha/saml-kit/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/xlgmokha/saml-kit/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/xlgmokha/saml-kit/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/xlgmokha/saml-kit/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/xlgmokha/saml-kit/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/xlgmokha/saml-kit/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/xlgmokha/saml-kit/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/xlgmokha/saml-kit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/xlgmokha/saml-kit/compare/v0.3.6...v1.0.0
[0.3.6]: https://github.com/xlgmokha/saml-kit/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/xlgmokha/saml-kit/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/xlgmokha/saml-kit/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/xlgmokha/saml-kit/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/xlgmokha/saml-kit/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/xlgmokha/saml-kit/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/xlgmokha/saml-kit/compare/v0.2.18...v0.3.0
[0.2.18]: https://github.com/xlgmokha/saml-kit/compare/v0.2.17...v0.2.18
[0.2.17]: https://github.com/xlgmokha/saml-kit/compare/v0.2.16...v0.2.17
[0.2.16]: https://github.com/xlgmokha/saml-kit/compare/v0.2.15...v0.2.16
[0.2.15]: https://github.com/xlgmokha/saml-kit/compare/v0.2.14...v0.2.15
[0.2.14]: https://github.com/xlgmokha/saml-kit/compare/v0.2.13...v0.2.14
[0.2.13]: https://github.com/xlgmokha/saml-kit/compare/v0.2.12...v0.2.13
[0.2.12]: https://github.com/xlgmokha/saml-kit/compare/v0.2.11...v0.2.12
[0.2.11]: https://github.com/xlgmokha/saml-kit/compare/v0.2.10...v0.2.11
[0.2.10]: https://github.com/xlgmokha/saml-kit/compare/v0.2.9...v0.2.10
[0.2.9]: https://github.com/xlgmokha/saml-kit/compare/v0.2.8...v0.2.9
[0.2.8]: https://github.com/xlgmokha/saml-kit/compare/v0.2.7...v0.2.8
[0.2.7]: https://github.com/xlgmokha/saml-kit/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/xlgmokha/saml-kit/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/xlgmokha/saml-kit/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/xlgmokha/saml-kit/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/xlgmokha/saml-kit/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/xlgmokha/saml-kit/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/xlgmokha/saml-kit/compare/v0.1.0...v0.2.1
