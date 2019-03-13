#!/bin/bash

function verify_subject()
{
    local subject="$1"
    local result=0
    if [ "${subject:0:8}" == "Revert \"" ] && [ "${subject: -1}" == "\"" ] ; then
        return 0
    fi
    if [ "${#subject}" -gt 72 ]; then
        echo "ERROR: The subject MUST be maximum 72 characters long." >&2
        result=1
    elif [ "${#subject}" -gt 50 ]; then
        echo "WARNING: The subject SHOULD be maximum 50 characters long." >&2
        result=0
    fi
    if [ "${subject: -1}" == "." ]; then
        echo "ERROR: The subject MUST not be finished with period." >&2
        result=1
    fi
    case ${subject:0:1} in
        [[:lower:]])
            echo "ERROR: The subject MUST start with capital letter." >&2
            result=1
            ;;
    esac
    local TICKET_REGEXP="[a-zA-Z]\+-[0-9]\+"
    local ticket_number=
    ticket_number="$(grep --only-matching "${TICKET_REGEXP}" <<< "${subject}")"
    if [ -n "${ticket_number}" ]; then
        echo "ERROR: The subject MUST NOT contain ticket number (${ticket_number})."
        result=1
    fi
    return ${result}
}

function verify_body_line()
{
    local body_line="$1"
    local line_number="$2"
    local result=0

    if [ "${#body_line}" -gt 72 ]; then
        echo "ERROR: The commit message MUST be wrapped into 72 characters long lines. (line: $line_number)" >&2
        result=1
    fi
    return ${result}
}

function verify_no_consecitive_blank_lines() {
    local commit_message="$1"
    local result=0

    commit_message_without_consecutive_empty_lines="$(grep -A1 . <<< "${commit_message}" | grep --invert-match "^--$")"

    if [ "${commit_message}" != "${commit_message_without_consecutive_empty_lines}" ]; then
        echo "ERROR: The commit message MUST NOT contain consecutive blank lines." >&2
        result=1
    fi

    return ${result}
}

function verify_commit_message()
{
    local commit_message=

    local result=0
    mapfile -t commit_message <<< "$1"
    if ! verify_subject "${commit_message[0]}"; then
        result=1
    fi

    if [ -n "${commit_message[1]:-}" ]; then
        echo "ERROR: The second line of the commit message MUST BE an empty line." >&2
        result=1
    fi

    if ! verify_no_consecitive_blank_lines "${1}"; then
        result=1
    fi
    local line_number=3
    for line in "${commit_message[@]:2}"
    do
        if ! verify_body_line "${line}" "${line_number}"; then
            result=1
        fi
        (( line_number ++ ))
    done
    return ${result}
}
