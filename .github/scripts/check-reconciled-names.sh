#!/bin/sh
# Checks that a reconcile agent examined every skill or agent.
#
# Usage: check-reconciled-names.sh <kind> <expected-names-file> <agent-output-file>
#
#   kind                 label used in messages, for example skills or agents
#   expected-names-file  one expected folder name per line
#   agent-output-file    the agent's captured final response
#
# The agent output must hold exactly one line RECONCILED-BEGIN and one later
# line RECONCILED-END, with one folder name per line between them. Leading and
# trailing whitespace, carriage returns, a leading "- " or "* " bullet and
# surrounding backticks are ignored, as are blank lines and repeated names.
# Fails, reporting every missing and every unknown name, unless the listed
# names are exactly the expected names.

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

# Trims whitespace and carriage returns from every line of stdin.
trim_lines() {
    tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

[ "$#" -eq 3 ] || die "Usage: check-reconciled-names.sh <kind> <expected-names-file> <agent-output-file>"

kind=$1
expected_file=$2
output_file=$3

[ -f "${expected_file}" ] || die "Expected ${kind} list not found: ${expected_file}"
[ -f "${output_file}" ] || die "Agent output not found: ${output_file}"

work=$(mktemp -d) || die "Could not create a temporary directory"
trap 'rm -rf "${work}"' EXIT
trap 'exit 1' HUP INT TERM

trim_lines <"${expected_file}" | grep -v '^$' | LC_ALL=C sort -u >"${work}/expected"
[ -s "${work}/expected" ] || die "Expected ${kind} list is empty: ${expected_file}"

trim_lines <"${output_file}" >"${work}/output"

# Exit status: 2 no BEGIN, 3 more than one BEGIN or END, 4 END before BEGIN or missing.
awk -v names="${work}/block" '
    BEGIN { printf "" > names }
    $0 == "RECONCILED-BEGIN" { begins++; inside = 1; next }
    $0 == "RECONCILED-END" { ends++; if (!inside) misplaced = 1; inside = 0; next }
    inside { print > names }
    END {
        if (begins == 0) exit 2
        if (begins > 1 || ends > 1) exit 3
        if (ends == 0 || misplaced) exit 4
    }
' "${work}/output"
status=$?

case "${status}" in
0) ;;
2) die "The ${kind} agent output has no RECONCILED-BEGIN line, so the ${kind} it examined are unknown" ;;
3) die "The ${kind} agent output has more than one RECONCILED-BEGIN or RECONCILED-END line" ;;
4) die "The ${kind} agent output has no RECONCILED-END line after its RECONCILED-BEGIN line" ;;
*) die "Could not read the ${kind} agent output (awk exit status ${status})" ;;
esac

# shellcheck disable=SC2016 # the backticks are literal characters to strip, not command substitution
sed 's/^[-*][[:space:]]*//; s/^`//; s/`$//' "${work}/block" | trim_lines | grep -v '^$' | LC_ALL=C sort -u >"${work}/listed"

LC_ALL=C comm -23 "${work}/expected" "${work}/listed" >"${work}/missing"
LC_ALL=C comm -13 "${work}/expected" "${work}/listed" >"${work}/unknown"

[ -s "${work}/missing" ] || [ -s "${work}/unknown" ] || {
    success "The ${kind} agent examined all $(wc -l <"${work}/expected" | tr -d ' ') ${kind}"
    exit 0
}

info "Comparing the ${kind} the agent listed with the ${kind} in the checkout"

while IFS= read -r name; do
    annotate_error "❌ The ${kind} agent did not list ${name}, so it may not have examined it"
done <"${work}/missing"

while IFS= read -r name; do
    annotate_error "❌ The ${kind} agent listed ${name}, which is not one of the ${kind} in the checkout"
done <"${work}/unknown"

die "The ${kind} agent did not examine exactly the ${kind} in the checkout: $(wc -l <"${work}/missing" | tr -d ' ') missing, $(wc -l <"${work}/unknown" | tr -d ' ') unknown"
