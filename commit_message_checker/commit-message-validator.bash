verify_commit_message() {
    local commit_message="$1"
    AWK=awk
    if [ -x /usr/xpg4/bin/awk ]; then
        # Solaris AWK is just too broken
        AWK=/usr/xpg4/bin/awk
    fi

    # How this works:
    # = checks length of Subject (first line of commit message)
    #    - It should be maximum 50 characters long -> however a little bit longer accepted
    #    - It MUST NOT be longer then 72 characters long -> rejected
    #    - It MUST NOT ends with puctuation marks -> rejected
    # - Check 2nd line -> It MUST be empty -> otherwise rejected
    # - Every line MUST BE maximum 72 characters long -> otherwise rejected
    #     - Exception: links -> accepted
    # - Check consecutive empty lines
    #     - 0 or 1 -> accepted
    #     - >1 -> rejected
    $AWK '
    BEGIN {
        if (match(ENVIRON["OS"], "Windows")) {
            RS="\r?\n" # Required on recent Cygwin
        }
        blankLines = 0
        isSecondLineEmpty = 0
        numberOfErrors = 0
        numberOfWarnings = 0
    }

    # Check blank lines
    /^$/ {
        if (NR == 2) {
            isSecondLinEmpty = 1
        }
        blankLines++
        next
    }
    (blankLines > 0) {
	if (blankLines > 1) {
           print "ERROR: The commit message contains more than 1 consecutive blank lines -> lines:", NR-blankLines , "-", NR-1
           numberOfErrors += 1
        }
        blankLines = 0
    }

    # Skip comments
    /^#/ {
        next
    }

    # Check emptyness of second line
    (NR == 2 && isSecondLineEmpty == 0) {
       print "ERROR: The second line of the commit message MUST BE an empty line."
       print " *", $0
       numberOfErrors += 1
    }

    # Verify Subject of commit message
    (length($0) > 50 && length($0) <= 72 && NR == 1) {
        print "WARNING: The subject SHOULD be maximum 50 characters long"
        print " *", $0
        print "                                                     ^"
        numberOfWarnings += 1
    }

    /^[[:lower:]]/ {
        if (NR == 1) {
            print "ERROR: The subject MUST begin with capital letter"
            print " *", $0
            print "   ^"
            numberOfErrors += 1
        }
    }

    /[.!?,;:\-_()\[\]{}]$/ {
        if (NR == 1) {
            print "ERROR: The subject MUST NOT end with punctuation mark -> line:", NR
            print " *", $0, "<--"
            numberOfErrors += 1
        }
    }

    match($0, /[A-Z][A-Z0-9]+-[0-9]+/, m) {
        if (NR == 1) {
            print "ERROR: The subject MUST NOT contain ticket number"
            print " *", m[0]
            numberOfErrors += 1
        }
    }

    (length($0) > 72 && NR == 1) {
        if (substr($0, 1, 8) != "Revert \"") {
            print "ERROR: The subject is longer than 72 characters -> line:", NR
            numberOfErrors += 1
            print " *", $0
            print "                                                                           ^"
        }
    }

    # Skip checking length if it is an URL
    /(https?|ftp|file):\/\/[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]/ {
        next
    }

    # Verify length of lines in commit message
    (length($0) > 72 && NR != 1){
        print "ERROR: Line is longer than 72 characters -> line:", NR
        print " *", $0
        print "                                                                           ^"
        numberOfErrors += 1
    }
    END {
        print "ERRORS:", numberOfErrors
        print "WARNINGS:", numberOfWarnings
        if(numberOfErrors > 0) {
           exit 1
        }
    }' <<< "${commit_message}"
    return $?
}

print_help_at_failure() {
    local commit_msg_file_name="$1"
    cat << EOM
    The commit message was saved into the '${commit_msg_file_name}' temporary file.
    Use the following command to edit and solve the issue with your commit:
        git commit -t ${commit_msg_file_name}

EOM
}

check_commit_message() {
    local commit_message="$1"
    local backup_commit_msg_file=".saved-commit.msg"
    rm -f "${backup_commit_msg_file}"
    verify_commit_message "${commit_message}"
    local exit_code=$?
    if (( exit_code != 0 )); then
        echo
        echo "Commit message is rejected"
        echo
        echo "${commit_message}" > "${backup_commit_msg_file}"
        print_help_at_failure "${backup_commit_msg_file}"
        exit 1
    fi
}

