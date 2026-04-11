#!/usr/bin/env bash
set -euo pipefail

# iLink - Common Functions
# Based on iLink-srs-v1.0.00

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

strip_metadata_and_collapse_blanks() {
  local file="$1"
  awk '
    BEGIN { in_meta=0; pending=0; prev_blank=0 }
    {
      line=$0
      if (in_meta) {
        if (line ~ /^---$/) { in_meta=0 }
        next
      }
      if (pending) {
        if (line ~ /^# ILINK-PROTOCOL-METADATA/) { in_meta=1; pending=0; next }
        print "---"
        pending=0
      }
      if (line ~ /^---$/) { pending=1; next }
      if (line ~ /^[[:space:]]*$/) {
        if (prev_blank) next
        prev_blank=1
        print ""
        next
      }
      prev_blank=0
      print line
    }
    END { if (pending) print "---" }
  ' "$file"
}

# FR-BSH-04: Metadata 印章注入
inject_metadata() {
  local file="$1"
  local role="$2"
  local status="$3"
  local target_files="${4:-}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')

  local hash_content
  hash_content=$(strip_metadata_and_collapse_blanks "$file")
  local source_hash
  if command -v md5sum &>/dev/null; then
    source_hash=$(printf "%s" "$hash_content" | md5sum | cut -d' ' -f1)
  else
    source_hash=$(printf "%s" "$hash_content" | md5 -q)
  fi
  [[ -z "$source_hash" ]] && source_hash="empty-doc"

  cp "$file" "$file.meta.bak"

  if grep -q "^# ILINK-PROTOCOL-METADATA" "$file"; then
    awk -v role="$role" -v ts="$timestamp" -v hash="$source_hash" -v status="$status" -v targets="$target_files" '
      /^# ILINK-PROTOCOL-METADATA/ { in_meta=1 }
      in_meta && /^Role:/ { print "Role: " role; next }
      in_meta && /^Current_Timestamp:/ { print "Current_Timestamp: " ts; next }
      in_meta && /^Normalized_Source_Hash:/ { print "Normalized_Source_Hash: " hash; next }
      in_meta && /^Status:/ { print "Status: " status; next }
      in_meta && /^Target_Files:/ { print "Target_Files: " targets; next }
      in_meta && /^---$/ { in_meta=0 }
      { print }
    ' "$file.meta.bak" > "$file"
    rm -f "$file.meta.bak"
    log_info "Updated metadata in $file"
  else
    {
      echo ""
      echo "---"
      echo "# ILINK-PROTOCOL-METADATA"
      echo "Protocol_Version: v1.0.00"
      echo "Role: $role"
      echo "AI_Vendor: —"
      echo "AI_Model: —"
      echo "Current_Timestamp: $timestamp"
      echo "Normalized_Source_Hash: $source_hash"
      echo "Target_Files: $target_files"
      echo "Status: $status"
      echo "---"
    } >> "$file"
    rm -f "$file.meta.bak"
    log_info "Appended metadata to $file"
  fi

  if ! grep -q "^Status: $status" "$file"; then
    log_error "Failed to update Status field in $file"
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
