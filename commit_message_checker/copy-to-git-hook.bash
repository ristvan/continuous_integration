#!/usr/bin/bash

GIT_VERSION=$(git --version)
echo ${GIT_VERSION}
GIT_DIR="$(git rev-parse --git-dir)"
COMMIT_MSG_HOOK="${GIT_DIR}/hooks/commit-msg"
if [ -n "${COMMIT_MSG_HOOK}" ]; then
  touch "${COMMIT_MSG_HOOK}"
fi
cat <<'EOM' >> "${COMMIT_MSG_HOOK}"
verify_commit_message "${MSG}"
ec=$?
if (( ${ec} != 0 )); then
    echo
    echo "Commit is rejected!!!"
    echo
    exit 1
fi
EOM
if [ ! -x "${COMMIT_MSG_HOOK}" ]; then
    chmod +x "${COMMIT_MSG_HOOK}"
fi
echo "Done"
