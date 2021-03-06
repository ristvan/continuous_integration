#!/bin/bash

source "commit_message.bash"

test_one_short_commit_message_should_be_ok()
{
    local commit_message="This is the subject of the commit message"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "" "${output}"
    assertEquals 0 "${result}"
}

test_one_short_commit_starts_with_small_letter_should_be_an_error()
{
    local commit_message="this is the subject of the commit message"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The subject MUST start with capital letter." "${output}"
    assertEquals 1 "${result}"
}

test_one_short_commit_message_ends_with_period_should_be_a_problem()
{
    local commit_message="This is the subject of the commit message."
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The subject MUST not be finished with period." "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_is_a_revert_commit_its_subject_can_be_longet_then_72_characters_should_be_a_warning()
{
    local commit_message="Revert \"This is the subject of the commit message that is just bit longer\""
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "" "${output}"
    assertEquals 0 "${result}"
}

test_when_commit_subject_is_between_50_and_72_characters_should_be_a_warning()
{
    local commit_message="This is the subject of the commit message that is just bit longer"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "WARNING: The subject SHOULD be maximum 50 characters long." "${output}"
    assertEquals 0 "${result}"
}

test_when_commit_subject_is_longer_than_72_characters_should_be_an_error()
{
    local commit_message="This is the subject of the commit message that is a much bit longer than it must be"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The subject MUST be maximum 72 characters long." "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_contains_a_ticket_number_should_be_an_error()
{
    local commit_message="[CIENGINE-12345] This is the subject of the commit"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The subject MUST NOT contain ticket number (CIENGINE-12345)." "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_starts_with_small_letter_and_the_length_is_between_50_and_72_should_be_an_error()
{
    local commit_message="this is the subject of the commit message that is just bit longer"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
WARNING: The subject SHOULD be maximum 50 characters long.
ERROR: The subject MUST start with capital letter.
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_the_second_line_of_commit_must_be_empty()
{
    local commit_message=
    read -r -d '' commit_message << EOM
This is the subject of the commit message
This the second line.
This is the first line of the body
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The second line of the commit message MUST BE an empty line." "${output}"
    assertEquals 1 "${result}"
}

test_the_commit_message_should_not_have_two_consecutive_empty_lines()
{
    local commit_message=
    read -r -d '' commit_message << EOM
This is the subject of the commit message


This is the first line of the body
EOM

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The commit message MUST NOT contain consecutive blank lines." "${output}"
    assertEquals 1 "${result}"

    read -r -d '' commit_message << EOM
This is the subject of the commit message

This is the first line of the body


Last Line of the body
EOM

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The commit message MUST NOT contain consecutive blank lines." "${output}"
    assertEquals 1 "${result}"
}


test_the_body_of_the_commit_must_be_wrapped_into_72_long_lines()
{
    local commit_message=
    read -r -d '' commit_message << EOM
This is the subject of the commit message

This is the first line of the body
This is a very long line in the body of commit message, that should not be there.
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "ERROR: The commit message MUST be wrapped into 72 characters long lines. (line: 4)" "${output}"
    assertEquals 1 "${result}"
}

test_when_multiple_errors_are_occuring_it_should_print_all_of_them()
{
    local commit_message=
    read -r -d '' commit_message << EOM
[CIENGINE-7657] This is the subject of the commit message that is a much bit longer
I forgot to delete it
This is the first line of the bodyl
This is a very long line in the body of commit message, that should not be there.
This is a very long line in the body of commit message is very long as well.
EOM
    local expected_output=
    read -r -d '' expected_output << EOM
ERROR: The subject MUST be maximum 72 characters long.
ERROR: The subject MUST NOT contain ticket number (CIENGINE-7657).
ERROR: The second line of the commit message MUST BE an empty line.
ERROR: The commit message MUST be wrapped into 72 characters long lines. (line: 4)
ERROR: The commit message MUST be wrapped into 72 characters long lines. (line: 5)
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

source "shunit2"
