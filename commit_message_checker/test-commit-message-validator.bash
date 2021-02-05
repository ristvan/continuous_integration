#!/bin/bash

source "commit-message-validator.bash"

test_one_short_commit_message_should_be_ok()
{
    local commit_message="This is the subject of the commit message"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}

test_one_short_commit_starts_with_small_letter_should_be_an_error()
{
    local commit_message="this is the subject of the commit message"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The subject MUST begin with capital letter
 * this is the subject of the commit message
   ^
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_one_short_commit_message_ends_with_period_should_be_a_problem()
{
    local commit_message="This is the subject of the commit message."
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The subject MUST NOT end with punctuation mark -> line: 1
 * This is the subject of the commit message. <--
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_is_a_revert_commit_its_subject_can_be_longet_then_72_characters_should_be_a_warning()
{
    local commit_message="Revert \"This is the subject of the commit message that is just bit longer\""
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}

test_when_commit_subject_is_between_50_and_72_characters_should_be_a_warning()
{
    local commit_message="This is the subject of the commit message that is just bit longer"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
WARNING: The subject SHOULD be maximum 50 characters long
 * This is the subject of the commit message that is just bit longer
                                                     ^
ERRORS: 0
WARNINGS: 1
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}

test_when_commit_subject_is_longer_than_72_characters_should_be_an_error()
{
    local commit_message="This is the subject of the commit message that is a much bit longer than it must be"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The subject is longer than 72 characters -> line: 1
 * This is the subject of the commit message that is a much bit longer than it must be
                                                                           ^
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_contains_a_ticket_number_should_be_an_error()
{
    local commit_message="[CIENGINE-12345] This is the subject of the commit"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The subject MUST NOT contain ticket number
 * CIENGINE-12345
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_commit_subject_starts_with_small_letter_and_the_length_is_between_50_and_72_should_be_an_error()
{
    local commit_message="this is the subject of the commit message that is just bit longer"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
WARNING: The subject SHOULD be maximum 50 characters long
 * this is the subject of the commit message that is just bit longer
                                                     ^
ERROR: The subject MUST begin with capital letter
 * this is the subject of the commit message that is just bit longer
   ^
ERRORS: 1
WARNINGS: 1
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
    read -r -d '' expected_output << EOM
ERROR: The second line of the commit message MUST BE an empty line.
 * This the second line.
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
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
    read -r -d '' expected_output << EOM
ERROR: The commit message contains more than 1 consecutive blank lines -> lines: 2 - 3
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"

    read -r -d '' commit_message << EOM
This is the subject of the commit message

This is the first line of the body


Last Line of the body
EOM

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The commit message contains more than 1 consecutive blank lines -> lines: 4 - 5
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
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
    read -r -d '' expected_output << EOM
ERROR: Line is longer than 72 characters -> line: 4
 * This is a very long line in the body of commit message, that should not be there.
                                                                           ^
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_a_url_is_longer_than_72_characters_is_is_not_and_error()
{
    local commit_message=
    read -r -d '' commit_message << EOM
This is the subject of the commit message

This is the first line of the body
This is a longier line in the body of commit message. It is ok.
https://developers.example.com/this/is/a/long/url/test/for/skipping/the/long/line/test
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
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
ERROR: The subject MUST NOT contain ticket number
 * CIENGINE-7657
ERROR: The subject is longer than 72 characters -> line: 1
 * [CIENGINE-7657] This is the subject of the commit message that is a much bit longer
                                                                           ^
ERROR: The second line of the commit message MUST BE an empty line.
 * I forgot to delete it
ERROR: Line is longer than 72 characters -> line: 4
 * This is a very long line in the body of commit message, that should not be there.
                                                                           ^
ERROR: Line is longer than 72 characters -> line: 5
 * This is a very long line in the body of commit message is very long as well.
                                                                           ^
ERRORS: 5
WARNINGS: 0
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_comment_is_included_it_should_be_skipped_during_verification() {
    local commit_message=
    read -r -d '' commit_message << EOM
This is the subject of the commit message

This is the first line of the body
# This is a very long comment line, however it should be skipped during the verification
# This is a short comment line it should be skipped as well
# This is a very long comment line, however it should be skipped during the verification
EOM
    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}


test_commit_first_line_finishes_with_capital_letter_should_be_ok()
{
    local commit_message="This is the subject of the commit MESSAGE"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}

test_commit_first_line_finishes_with_dash_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "-"
}

test_commit_first_line_finishes_with_dot_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "."
}

test_commit_first_line_finishes_with_exclamation_mark_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "!"
}

test_commit_first_line_finishes_with_question_mark_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "?"
}

test_commit_first_line_finishes_with_coma_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject ","
}

test_commit_first_line_finishes_with_semicolon_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject ";"
}

test_commit_first_line_finishes_with_colon_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject ":"
}

test_commit_first_line_finishes_with_underscore_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "_"
}

test_commit_first_line_finishes_with_parentheses_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "("
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject ")"
}

test_commit_first_line_finishes_with_square_bracket_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "["
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "]"
}

test_commit_first_line_finishes_with_curly_bracket_should_be_an_error()
{
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "{"
    assert_that_given_punctuation_mark_is_invalid_at_end_of_subject "}"
}

assert_that_given_punctuation_mark_is_invalid_at_end_of_subject() {
    local punctuation_mark="$1"
    local commit_message="This is the subject of the commit MESSAGE${punctuation_mark}"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERROR: The subject MUST NOT end with punctuation mark -> line: 1
 * This is the subject of the commit MESSAGE${punctuation_mark} <--
ERRORS: 1
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 1 "${result}"
}

test_when_component_names_added_it_should_be_accepted() {
    local commit_message="[COMPONENT][SUB_COMP] Move log to new folder"
    local result=0

    output="$(verify_commit_message "${commit_message}" 2>&1)"
    result=$?
    read -r -d '' expected_output << EOM
ERRORS: 0
WARNINGS: 0
EOM
    assertEquals "${expected_output}" "${output}"
    assertEquals 0 "${result}"
}

source "shunit2"
