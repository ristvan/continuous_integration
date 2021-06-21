#!/usr/bin/bash

function get_validator_script_path() {
    local script_dir=""

    script_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
    echo "${script_dir}/commit-message-validator.bash"
}

function create_hook_file_when_needed() {
    local commit_msg_hook_file="$1"
    if [ -n "${commit_msg_hook_file}" ]; then
        touch "${commit_msg_hook_file}"
    fi
}

function remove_old_commit_message_verification() {
    local commit_msg_hook="$1"
    local temp_file_name="${commit_msg_hook}.tmp.$$"
    sed '/^# begin of CMV/,/^# end of CMV/d' ${commit_msg_hook} >"${temp_file_name}"
    mv "${temp_file_name}" "${commit_msg_hook}"
}

function insert_commit_message_verification() {
    local commit_msg_hook="$1"
    local validator_script="$2"

    cat <<EOM >> "${commit_msg_hook}"
# begin of CMV
source "${validator_script}"
EOM

    cat <<'EOM' >> "${commit_msg_hook}"
check_commit_message "$(<"${MSG}")"
# end of CMV
EOM
}

function add_execution_permission() {
    local commit_msg_hook="$1"
    if [ ! -x "${commit_msg_hook}" ]; then
        chmod +x "${commit_msg_hook}"
    fi
}

VALIDATOR_SCRIPT="$(get_validator_script_path)"

GIT_VERSION=$(git --version)
echo ${GIT_VERSION}
GIT_DIR="$(git rev-parse --git-dir)"
COMMIT_MSG_HOOK="${GIT_DIR}/hooks/commit-msg"

create_hook_file_when_needed "${COMMIT_MSG_HOOK}"
remove_old_commit_message_verification "${COMMIT_MSG_HOOK}"
insert_commit_message_verification "${COMMIT_MSG_HOOK}" "${VALIDATOR_SCRIPT}"
add_execution_permission "${COMMIT_MSG_HOOK}"

echo "Done"
