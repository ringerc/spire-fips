# syntax = docker/dockerfile:1.6.0@sha256:ac85f380a63b13dfcefa89046420e1781752bab202122f8f50032edf31be0021
#
# This is a multi-arch build. It needs quemu, though most of the work is done
# by the build phase as a cross-arch build. See
# https://docs.docker.com/build/building/multi-platform/#install-qemu-manually
# for a quick way to set up qemu builds.

# Build stage
ARG goversion
FROM --platform=$BUILDPLATFORM goreleaser/goreleaser-cross:v1.24 AS builder
WORKDIR /spire
COPY go.* ./
# https://go.dev/ref/mod#module-cache
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .

ARG TARGETARCH

# Build the Spire executables, possibly cross-compiling
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    GOARCH=${TARGETARCH} goreleaser build -f .goreleaser.yml --skip=validate --clean --verbose --single-target

# Prepare the target image
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5 as spire-base
#COPY --link --from=builder --chown=root:root --chmod=755 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
WORKDIR /opt/spire

# Preparation environment for setting up directories without needing
# to run with qemu
FROM builder as prep-spire-server
RUN mkdir -p /spireroot/opt/spire/bin \
    /spireroot/etc/spire/server \
    /spireroot/run/spire/server/private \
    /spireroot/tmp/spire-server/private \
    /spireroot/var/lib/spire/server

FROM builder as prep-spire-agent
RUN mkdir -p /spireroot/opt/spire/bin \
    /spireroot/etc/spire/agent \
    /spireroot/run/spire/agent/public \
    /spireroot/tmp/spire-agent/public \
    /spireroot/var/lib/spire/agent

# For users that wish to run SPIRE containers with a specific uid and gid, the
# spireuid and spiregid arguments are provided. The default paths that SPIRE
# will try to read from, write to, and create at runtime are given the
# corresponding file ownership/permissions at build time.
# A default non-root user is defined for SPIRE Server and the OIDC Discovery
# Provider. The SPIRE Agent image runs as root by default to facilitate the
# sharing of the agent socket in Kubernetes environments.

# SPIRE Server
FROM spire-base AS spire-server
ARG spireuid=1000
ARG spiregid=1000
USER ${spireuid}:${spiregid}
ENTRYPOINT ["/opt/spire/bin/spire-server", "run"]
COPY --link --from=prep-spire-server --chown=${spireuid}:${spiregid} --chmod=755 /spireroot /
COPY --link --from=builder --chown=${spireuid}:${spiregid} --chmod=755 /spire/dist/spire-server /opt/spire/bin/

# SPIRE Agent
FROM spire-base AS spire-agent
ARG spireuid=0
ARG spiregid=0
USER ${spireuid}:${spiregid}
ENTRYPOINT ["/opt/spire/bin/spire-agent", "run"]
COPY --link --from=prep-spire-agent --chown=${spireuid}:${spiregid} --chmod=755 /spireroot /
COPY --link --from=builder --chown=${spireuid}:${spiregid} --chmod=755 /spire/dist/spire-agent /opt/spire/bin/

# OIDC Discovery Provider
FROM spire-base AS oidc-discovery-provider
ARG spireuid=1000
ARG spiregid=1000
USER ${spireuid}:${spiregid}
ENTRYPOINT ["/opt/spire/bin/oidc-discovery-provider"]
COPY --link --from=builder --chown=${spireuid}:${spiregid} --chmod=755 /spire/dist/oidc-discovery-provider /opt/spire/bin/
