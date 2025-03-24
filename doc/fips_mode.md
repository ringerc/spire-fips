# FIPS mode

Spire can be built to use a golang runtime that uses a FIPS 140 compliant cryptographic module.

There are three levels of FIPS support available.

* *Non-FIPS*. Spire is built with golang's standard cryptographic module,
  which is not FIPS 140 capable. This is the default.

  No special tags or flags required.

* *FIPS-140 capable*. This binary will detect the FIPS
  mode of the system  (`/proc/sys/crypto/fips_enabled` on Linux) and will use
  the FIPS 140 compliant cryptographic module if the system is in FIPS mode. If
  the system is not in FIPS mode, the binary will use the standard golang
  cryptographic module.

  Set `GOEXPERIMENT=boringssl CGO_ENABLED=1` in the environment when building.

* *FIPS-140 enforced*. This binary will only use the FIPS
  140 compliant cryptographic module. If the system is not in FIPS mode, the
  binary will not start. The [fipsonly](https://go.dev/src/crypto/tls/fipsonly/)
  package is used to enforce this.

  Set the same environment variables as for FIPS-140 capable, and also set
  `GOFLAGS=-tags fipsonly`.

A goreleaser configuration is provided for FIPS-enforcing builds, along with a
Dockerfile that uses them. To build a FIPS-140-enforced binary set:

```sh
goreleaser build -f .goreleaser.yml --skip=validate --verbose --single-target --clean                  
```

To build container images for amd64 and arm64:

```sh
# Enable cross-arch builders
docker run --privileged --rm tonistiigi/binfmt --install all
# Build for amd64 and arm64
docker buildx build --platform linux/amd64 --load -f Dockerfile --target spire-server --tag spire-server:latest-amd64 .
docker buildx build --platform linux/arm64 --load -f Dockerfile --target spire-server --tag spire-server:latest-arm64 .
```

For convenience, make flags are also exposed for binary (but not image) builds:

| Make flag        | FIPS capability   |
| ---------------- | ----------------- |
| *(none)*         | Non-FIPS          |
| `FIPS=1`         | FIPS-140 capable  |
| `FIPSONLY=1`     | FIPS-140 enforced |

See `pkg/common/entrypoint/fipsonly.go` in the Spire source tree for more details.
