#!/usr/bin/env bats
# Covers the up-front sudo rights check that ai/skills/install and
# ai/agents/install run for --system as a non-root user. sudo -v asks for a
# password even where NOPASSWD rules cover the commands the installer runs, so
# the check must be sudo -n true and must never call sudo -v.
#
# Never runs real sudo and never touches /etc or /usr/local: sudo and id are
# fakes on PATH. The fake sudo answers sudo -n true with FAKE_SUDO_N_TRUE_STATUS
# and refuses every other call, so an install that gets past the check stops at
# its first privileged step with "could not create".

bats_require_minimum_version 1.5.0

setup() {
    REPO_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    FAKE_BIN="${BATS_TEST_TMPDIR}/bin"
    FAKE_SUDO_LOG="${BATS_TEST_TMPDIR}/sudo.log"
    export FAKE_SUDO_LOG
    mkdir -p "${FAKE_BIN}" "${BATS_TEST_TMPDIR}/home"
    : > "${FAKE_SUDO_LOG}"

    cat > "${FAKE_BIN}/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_SUDO_LOG"
[ "$*" = "-n true" ] && exit "${FAKE_SUDO_N_TRUE_STATUS:-1}"
exit 1
EOF
    chmod +x "${FAKE_BIN}/sudo"

    # The rights check only runs for a non-root caller, so the test must not depend on who runs it.
    cat > "${FAKE_BIN}/id" <<'EOF'
#!/bin/sh
echo 1000
EOF
    chmod +x "${FAKE_BIN}/id"

    export HOME="${BATS_TEST_TMPDIR}/home"
    export PATH="${FAKE_BIN}:${PATH}"
}

assert_sudo_validate_never_called() {
    if grep -qE '(^| )(-v|--validate)( |$)' "${FAKE_SUDO_LOG}"; then
        echo "sudo -v was called:" >&2
        cat "${FAKE_SUDO_LOG}" >&2
        return 1
    fi
}

assert_rights_check_passed() {
    local installer="$1"
    local target="$2"

    export FAKE_SUDO_N_TRUE_STATUS=0
    run "${REPO_DIR}/${installer}" --system

    [ "${status}" -ne 0 ]
    [[ "${output}" != *"--system needs sudo rights"* ]]
    [[ "${output}" == *"could not create ${target}"* ]]
    grep -qx -- '-n true' "${FAKE_SUDO_LOG}"
    assert_sudo_validate_never_called
}

assert_rights_check_failed() {
    local installer="$1"

    export FAKE_SUDO_N_TRUE_STATUS=1
    run "${REPO_DIR}/${installer}" --system

    [ "${status}" -ne 0 ]
    [[ "${output}" == *"--system needs sudo rights"* ]]
    [ "$(< "${FAKE_SUDO_LOG}")" = "-n true" ]
}

@test "ai/skills/install --system gets past the rights check when sudo -n true succeeds" {
    assert_rights_check_passed ai/skills/install /etc/claude-code/.claude/skills
}

@test "ai/skills/install --system stops with a rights error when sudo -n true fails" {
    assert_rights_check_failed ai/skills/install
}

@test "ai/agents/install --system gets past the rights check when sudo -n true succeeds" {
    assert_rights_check_passed ai/agents/install /etc/claude-code/.claude/agents
}

@test "ai/agents/install --system stops with a rights error when sudo -n true fails" {
    assert_rights_check_failed ai/agents/install
}
