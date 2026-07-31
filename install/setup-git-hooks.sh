#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

git -C "$REPO_DIR" config core.hooksPath .githooks

if command -v gitleaks >/dev/null 2>&1; then
    printf '✓ Hooks de segurança ativados em %s/.githooks\n' "$REPO_DIR"
else
    printf '⚠ Hooks ativados, mas gitleaks ainda não está instalado.\n' >&2
    printf '  Instale as dependências antes do próximo commit ou push.\n' >&2
fi
