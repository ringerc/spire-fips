# FIPS mode

Spire can be built to use a golang runtime that uses a FIPS 140 compliant cryptographic module.

There are three levels of FIPS support available.

* *Non-FIPS*. Spire is built with golang's standard cryptographic module,
  which is not FIPS 140 capable. This is the default.
* *FIPS-140 capable*. This binary will detect the FIPS
  mode of the system  (`/proc/sys/crypto/fips_enabled` on Linux) and will use
  the FIPS 140 compliant cryptographic module if the system is in FIPS mode. If
  the system is not in FIPS mode, the binary will use the standard golang
  cryptographic module.
* *FIPS-140 enforced*. This binary will only use the FIPS
  140 compliant cryptographic module. If the system is not in FIPS mode, the
  binary will not start. The [fipsonly](https://go.dev/src/crypto/tls/fipsonly/)
  package is used to enforce this.

Make flags control the FIPS capability of the binaries and/or container images.

| Make flag        | FIPS capability   |
| ---------------- | ----------------- |
| *(none)*         | Non-FIPS          |
| `FIPS=true`      | FIPS-140 capable  |
| `FIPSONLY=true`  | FIPS-140 enforced |

These flags may also be set as environment variables at build-time.

A `FIPSONLY=true` build will fail if the golang toolchain and runtime in use
are not FIPS-capable.

`FIPS=true` currently guarantees that the golang runtime is FIPS-capable, since
golang boringcrypto has FIPS support, but nothing is in place to enforce this.

See `pkg/common/entrypoint/fipsonly.go` in the Spire source tree for more details.
