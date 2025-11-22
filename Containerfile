# Containerfile – multi-stage, minimal, secure
FROM alpine:3.20 AS builder
RUN apk add --no-cache buildah podman

FROM alpine:3.20
LABEL org.opencontainers.image.source="https://github.com/sabermaraghi/bash-mastery-devops"
LABEL org.opencontainers.image.authors="Saber Maraghi"
LABEL org.opencontainers.image.title="Bash Mastery DevOps CLI"

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git \
    coreutils \
    buildah \
    podman \
    cosign

# Copy entire scripts directory
COPY scripts/ci-cd /usr/local/bin/ci-cd
ENV PATH="/usr/local/bin/ci-cd:${PATH}"

ENTRYPOINT ["ci-cd.sh"]
CMD ["--help"]





#FROM alpine:latest
#CMD ["echo", "Hello from Day 17 Pipeline!"]
