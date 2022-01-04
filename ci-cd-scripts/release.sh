#!/usr/bin/env bash

#
# prepare data for the release step. Here we upload all the metadata to the Inventory Repo.
# If you want to add any information or artifact to the inventory repo then use the "cocoa inventory add command"
#

if [ "$SCM_TYPE" == "gitlab" ]; then
  GITLAB_TOKEN="$(cat ../git-token)"
  GITLAB_URL="$SCM_API_URL"
  export GITLAB_TOKEN
  export GITLAB_URL
else
  GHE_TOKEN="$(cat ../git-token)"
  export GHE_TOKEN
fi

export COMMIT_SHA="$(cat /config/git-commit)"
#export APP_NAME="$(cat /config/app-name)"
export APP_NAME=${IMAGES_NAME_BACKEND}

INVENTORY_REPO="$(cat /config/inventory-url)"
GHE_ORG=${INVENTORY_REPO%/*}
export GHE_ORG=${GHE_ORG##*/}
GHE_REPO=${INVENTORY_REPO##*/}
export GHE_REPO=${GHE_REPO%.git}

set +e
    REPOSITORY="$(cat /config/repository)"
    #TAG="$(cat /config/custom-image-tag)"
    TAG=$(get_env "REGISTRY_TAG")
set -e

export APP_REPO="$(cat /config/repository-url)"
APP_REPO_ORG=${APP_REPO%/*}
export APP_REPO_ORG=${APP_REPO_ORG##*/}

if [[ "${REPOSITORY}" ]]; then
    export APP_REPO_NAME=$(basename $REPOSITORY .git)
    APP_NAME=$APP_REPO_NAME
else
    APP_REPO_NAME=${APP_REPO##*/}
    export APP_REPO_NAME=${APP_REPO_NAME%.git}
fi
APP_NAME=$(get_env "IMAGES_NAME_BACKEND")

if [ "$SCM_TYPE" == "gitlab" ]; then
    id=$(curl --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" ${SCM_API_URL}/projects/${APP_REPO_ORG}%2F${APP_REPO_NAME} | jq .id)
    ARTIFACT="${SCM_API_URL}/projects/${id}/repository/files/deployments%2Fkubernetes.yml/raw?ref=${COMMIT_SHA}"
else
    ARTIFACT="https://raw.github.ibm.com/${APP_REPO_ORG}/${APP_REPO_NAME}/${COMMIT_SHA}/deployments/kubernetes.yml"
fi

echo "niklas"
echo ${REPOSITORY}
echo ${TAG}
echo ${APP_REPO}
echo ${APP_REPO_ORG}
echo ${APP_REPO_NAME}
echo ${APP_NAME}
echo ${ARTIFACT}
echo ${SCM_API_URL}


IMAGE_ARTIFACT="$(cat /config/artifact)"
SIGNATURE="$(cat /config/signature)"
if [[ "${TAG}" ]]; then
    APP_ARTIFACTS='{ "signature": "'${SIGNATURE}'", "provenance": "'${IMAGE_ARTIFACT}'", "tag": "'${TAG}'" }'
else
    APP_ARTIFACTS='{ "signature": "'${SIGNATURE}'", "provenance": "'${IMAGE_ARTIFACT}'" }'
fi

echo ${IMAGE_ARTIFACT}
echo ${APP_ARTIFACTS}

#
# add to inventory
#

cocoa inventory add \
    --artifact="${ARTIFACT}" \
    --repository-url="${APP_REPO}" \
    --commit-sha="${COMMIT_SHA}" \
    --build-number="${BUILD_NUMBER}" \
    --pipeline-run-id="${PIPELINE_RUN_ID}" \
    --version="$(cat /config/version)" \
    --name="${APP_REPO_NAME}_deployment" \
    --git-provider="${SCM_TYPE}"

cocoa inventory add \
    --artifact="${IMAGE_ARTIFACT}" \
    --repository-url="${APP_REPO}" \
    --commit-sha="${COMMIT_SHA}" \
    --build-number="${BUILD_NUMBER}" \
    --pipeline-run-id="${PIPELINE_RUN_ID}" \
    --version="$(cat /config/version)" \
    --name="${APP_REPO_NAME}" \
    --app-artifacts="${APP_ARTIFACTS}" \
    --git-provider="${SCM_TYPE}"
