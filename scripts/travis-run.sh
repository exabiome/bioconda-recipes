#!/bin/bash
set -euo pipefail


# obtain recipes that changed in this commit
RECIPES=""
git diff master HEAD --exit-code --name-only scripts/env_matrix.yml
if [ $? -eq 1 ] || [ $TRAVIS_EVENT_TYPE == "cron" ]
then
    echo "considering all recipes because either env matrix was changed or build is triggered via cron"
else
    RECIPES=$(git diff --relative=recipes --name-only $TRAVIS_COMMIT_RANGE recipes/*/meta.yaml recipes/*/*/meta.yaml | xargs dirname)
    echo "considering changed recipes:"
    echo $RECIPES
fi


export PATH=/anaconda/bin:$PATH

if [[ $TRAVIS_BRANCH = "master" && "$TRAVIS_PULL_REQUEST" = "false" ]]
then
   echo "Create Container push commands file: ${TRAVIS_BUILD_DIR}/container_push_commands.sh"
   export CONTAINER_PUSH_COMMANDS_PATH=${TRAVIS_BUILD_DIR}/container_push_commands.sh
   touch $CONTAINER_PUSH_COMMANDS_PATH
fi

if [[ $TRAVIS_OS_NAME = "linux" ]]
then
    USE_DOCKER="--docker"
else
    USE_DOCKER=""
fi

set -x; bioconda-utils build recipes config.yml $USE_DOCKER $BIOCONDA_UTILS_ARGS --packages $RECIPES; set +x;


if [[ $TRAVIS_OS_NAME = "linux" ]]
then
    if [[ $TRAVIS_BRANCH = "master" && "$TRAVIS_PULL_REQUEST" = "false" ]]
    then
        echo "Push containers to quay.io"
        cat $CONTAINER_PUSH_COMMANDS_PATH
        bash $CONTAINER_PUSH_COMMANDS_PATH
    fi
fi
