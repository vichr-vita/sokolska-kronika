#!/usr/bin/env bash

set -euo pipefail

if ! command -v typst >/dev/null 2>&1; then
  printf 'Error: Typst 0.15.1 is required but "typst" was not found in PATH.\n' >&2
  exit 127
fi

script_dir="${BASH_SOURCE[0]%/*}"
[[ "$script_dir" == "${BASH_SOURCE[0]}" ]] && script_dir="."
repo_root="$(cd -- "$script_dir" && pwd)"
cd -- "$repo_root"

version="3_0_0"
prewar_output="out/predvalecna_kronika_v${version}.pdf"
contemporary_output="out/soucasna_kronika_v${version}.pdf"

mkdir -p out
rm -f -- "$prewar_output" "$contemporary_output"

compile() {
  local label="$1"
  local source="$2"
  local output="$3"

  printf 'Building %s...\n' "$label"
  if ! typst compile --root . "$source" "$output"; then
    printf 'Error: failed to compile %s from %s.\n' "$label" "$source" >&2
    return 1
  fi
  printf 'Created %s\n' "$output"
}

compile "Předválečná kronika" "chronicles/predvalecna/main.typ" "$prewar_output"
compile "Současná kronika" "chronicles/soucasna/main.typ" "$contemporary_output"

printf 'Both chronicles built successfully.\n'
