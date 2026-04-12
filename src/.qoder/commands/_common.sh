#!/usr/bin/env bash
set -euo pipefail

# iLink - Common Functions
# Based on iLink Root Spec v1.1.01

story_required() {
  if [[ $# -lt 1 || -z "${1}" ]]; then
    echo "Usage: $0 <story>" >&2
    exit 2
  fi
}

story_dir() {
  echo "iLink-doc/$1"
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing file: $1" >&2
    exit 3
  fi
}

extract_metadata() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^# ILINK-PROTOCOL-METADATA/ { in_meta=1; next }
    in_meta && $0 ~ "^"key":" { sub("^"key":[[:space:]]*", ""); print; exit }
    in_meta && /^---$/ { in_meta=0 }
  ' "$file" | tr -d '\r'
}

check_status() {
  local file="$1"
  if [[ -f "$file" ]]; then
    extract_metadata "$file" "Status"
  else
    echo "MISSING"
  fi
}

write_doc_sep() {
  local out="$1"
  local title="$2"
  {
    echo
    echo "---"
    echo "# $title"
    echo
  } >> "$out"
}

log_info() {
  echo "[flow] $1"
}

log_error() {
  echo "[flow] ERROR: $1" >&2
}

log_warn() {
  echo "[flow] WARN: $1"
}

# Extract a section from a file between start and end patterns
extract_section() {
  local file="$1"
  local start_pat="$2"
  local end_pat="$3"
  awk -v start="$start_pat" -v end="$end_pat" '
    $0 ~ start {in_sec=1; print; next}
    $0 ~ end && in_sec==1 {exit}
    in_sec==1 {print}
  ' "$file"
}

# Extract file paths enclosed in backticks
extract_backtick_paths() {
  sed -n 's/.*`\([^`]*\)`.*/\1/p' | sed '/^$/d' | sort -u
}

# Extract file paths from TASK_ALLOCATION section
extract_task_allocation_paths() {
  local file="$1"
  extract_section "$file" "\\[TASK_ALLOCATION\\]" "^##[[:space:]]+" | extract_backtick_paths
}

# Validate path safety (no absolute, home, or traversal paths)
is_path_safe() {
  local p="$1"
  if [[ "$p" == /* || "$p" == ~* || "$p" == *".."* ]]; then
    return 1
  fi
  return 0
}

update_status() {
  local file="$1"
  local new_status="$2"
  if ! grep -q "^# ILINK-PROTOCOL-METADATA" "$file"; then
    log_error "Metadata block not found in $file"
    return 1
  fi
  awk -v status="$new_status" '
    /^# ILINK-PROTOCOL-METADATA/ { in_meta=1 }
    in_meta && /^Status:/ { print "Status: " status; next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

get_retry_count() {
  local base_dir="$1"
  local retry_file="$base_dir/.retry_count"
  if [[ -f "$retry_file" ]]; then
    cat "$retry_file"
  else
    echo "0"
  fi
}

increment_retry_count() {
  local base_dir="$1"
  local retry_file="$base_dir/.retry_count"
  local count
  count=$(get_retry_count "$base_dir")
  echo $((count + 1)) > "$retry_file"
}

reset_retry_count() {
  local base_dir="$1"
  local retry_file="$base_dir/.retry_count"
  rm -f "$retry_file"
}

is_reflux_mode() {
  local base_dir="$1"
  local story="$2"
  local review_doc="$base_dir/${story}-review.master.md"

  if [[ -f "$review_doc" ]]; then
    local status
    status=$(check_status "$review_doc")
    if [[ "$status" == "FAIL_BACK_TO_CODER" ]]; then
      return 0
    fi
  fi
  return 1
}
