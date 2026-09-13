#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="${1:-}"

if [ -z "$IMAGE_REF" ]; then
  echo "ERROR: Image reference is required."
  echo "Usage: $0 <image-reference>"
  exit 1
fi

echo "Verifying Cosign signature for: $IMAGE_REF"

cosign verify "$IMAGE_REF" \
  --certificate-identity-regexp "https://github.com/sentinelpay-team/Sentinelpay/.github/workflows/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

echo "Verifying SBOM attestation for: $IMAGE_REF"

cosign verify-attestation "$IMAGE_REF" \
  --type cyclonedx \
  --certificate-identity-regexp "https://github.com/sentinelpay-team/Sentinelpay/.github/workflows/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

echo "Supply-chain verification passed for: $IMAGE_REF"
