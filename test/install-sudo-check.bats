#!/usr/bin/env bats
# Covers how ai/skills/install and ai/agents/install use sudo for --system as a
# non-root user. Whatever runs the installer has already used sudo, so they make
# no up-front rights probe (no sudo -n true, no sudo -v) and go straight to their
# first privileged step, whose own failure reports the problem.
#
# Never runs real sudo and never touches /etc or /usr/local: sudo and id are
# fakes on PATH. The fake sudo logs and refuses every call, so the install stops
# at its first privileged step with "could not create".

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
exit 1
EOF
    chmod +x "${FAKE_BIN}/sudo"

    # sudo is only used for a non-root caller, so the test must not depend on who runs it.
    cat > "${FAKE_BIN}/id" <<'EOF'
#!/bin/sh
echo 1000
EOF
    chmod +x "${FAKE_BIN}/id"

    export HOME="${BATS_TEST_TMPDIR}/home"
    export PATH="${FAKE_BIN}:${PATH}"
}

assert_goes_straight_to_first_privileged_step() {
    local installer="$1"
    local target="$2"

    run "${REPO_DIR}/${installer}" --system

    [ "${status}" -ne 0 ]
    [[ "${output}" == *"could not create ${target}"* ]]
    [[ "${output}" != *"--system needs sudo rights"* ]]
    # The first sudo call is the privileged step itself, with no probe before it.
    [ "$(head -n 1 "${FAKE_SUDO_LOG}")" = "mkdir -p ${target}" ]
    # A short-option bundle such as -nv or -kv validates just as -v does.
    if grep -qE -e '^-n true$' -e '(^| )(-[a-zA-Z]*v[a-zA-Z]*|--validate)( |$)' "${FAKE_SUDO_LOG}"; then
        echo "an up-front sudo probe was called:" >&2
        cat "${FAKE_SUDO_LOG}" >&2
        return 1
    fi
}

@test "ai/skills/install --system makes no up-front sudo probe and goes straight to creating its target" {
    assert_goes_straight_to_first_privileged_step ai/skills/install /etc/claude-code/.claude/skills
}

@test "ai/agents/install --system makes no up-front sudo probe and goes straight to creating its target" {
    assert_goes_straight_to_first_privileged_step ai/agents/install /etc/claude-code/.claude/agents
}
