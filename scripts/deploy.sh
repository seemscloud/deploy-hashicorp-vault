#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_DIR}"

RELEASE_NAME="${RELEASE_NAME:-vault}"
NAMESPACE="${NAMESPACE:-vault}"
CHART="${CHART:-hashicorp/vault}"
CHART_VERSION="${CHART_VERSION:-0.34.0}"
VALUES_FILE="${VALUES_FILE:-chart/values.yaml}"

helm upgrade --install "${RELEASE_NAME}" "${CHART}" \
  --version "${CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  --server-side=false \
  --values "${VALUES_FILE}"
