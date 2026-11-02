#!/bin/sh
# Checks that reconciled skills or agents hold no stale-capability markers.
#
# Usage: check-stale-markers.sh <kind> <hits-file> <directory>...
#
#   kind       label used in messages, for example skills or agents
#   hits-file  written with one path:line:text entry per stale line found
#   directory  a folder to search, for example ai/skills
#
# Run from the repository root. A stale-capability marker is wording that
# says an operation cannot be done yet, such as "not available yet" or "no
# cfwf command yet". The instruction files are the source of truth, so a
# marker in a generated file is stale unless the instruction files
# (.ai-instructions and ai/global, which the reconcile agents cannot edit)
# use the same wording. Each marker is therefore checked only while those
# files hold no match for it, and is skipped, with a notice, once they do.
#
# A reconcile agent can report every file as examined and still leave a
# stale passage in place; this check is the deterministic backstop for that.
# Fails, annotating every stale line, if any marker is found.

die() {
    if [ -t 2 ]; then
        printf '\n\033[31m✗\033[0m %s\n' "$*" >&2
    else
        printf '\n✗ %s\n' "$*" >&2
    fi
    exit 1
}

success() {
    if [ -t 1 ]; then
        printf '\n\033[32m✓\033[0m %s\n' "$*"
    else
        printf '\n✓ %s\n' "$*"
    fi
}

info() {
    if [ -t 1 ]; then
        printf '\n\033[32m→\033[0m %s\n' "$*"
    else
        printf '\n→ %s\n' "$*"
    fi
}

# GitHub Actions error annotation, so each problem is listed on the run summary.
annotate_error() {
    printf '::error::%s\n' "$*"
}

[ "$#" -ge 3 ] || die "Usage: check-stale-markers.sh <kind> <hits-file> <directory>..."

kind=$1
hits_file=$2
shift 2

for dir in "$@"; do
    [ -d "${dir}" ] || die "Directory to check not found: ${dir}"
done
[ -d ai/global ] || die "ai/global not found; run from the repository root"

: >"${hits_file}" || die "Could not write ${hits_file}"

# Extended regular expressions, matched case-insensitively, one per line.
# shellcheck disable=SC2016 # the backticks are literal characters to match, not command substitution
markers='not (yet )?available (to agents )?yet
not available to agents
not yet available
no `?cfwf`? command( or MCP tool)? yet'

info "Checking the ${kind} for stale-capability markers"

printf '%s\n' "${markers}" | while IFS= read -r marker; do
    if grep -q -r -i -E -- "${marker}" .ai-instructions ai/global; then
        info "Skipping marker '${marker}': the instruction files use it"
        continue
    fi
    grep -r -n -i -E -- "${marker}" "$@" >>"${hits_file}"
done

[ -s "${hits_file}" ] || {
    success "The ${kind} hold no stale-capability markers"
    exit 0
}

LC_ALL=C sort -u -o "${hits_file}" "${hits_file}"

while IFS= read -r hit; do
    annotate_error "❌ Stale-capability wording with no source in the instruction files: ${hit}"
done <"${hits_file}"

die "The ${kind} hold $(wc -l <"${hits_file}" | tr -d ' ') line(s) of stale-capability wording; regenerate them from their sources"
