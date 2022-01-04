#!/usr/bin/env bash

GITLAB_TOKEN=$(cat "$WORKSPACE/secrets/git-token")
GITLAB_URL="$(get_env SCM_API_URL)"
OWNER=$(jq -r '.services[] | select(.toolchain_binding.name=="app-repo") | .parameters.owner_id' /toolchain/toolchain.json)
REPO=$(jq -r '.services[] | select(.toolchain_binding.name=="app-repo") | .parameters.repo_name' /toolchain/toolchain.json)
curl --location --request PUT "${GITLAB_URL}/projects/${OWNER}%2F${REPO}/" \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "only_allow_merge_if_pipeline_succeeds": true
    }'

echo "ci-cd-scripts/code_setup.sh"
export PARENT=$(get_env "multi-tenancy")
echo $PARENT

cd ..
git clone $PARENT

cd multi-tenancy
GIT_COMMIT=$(git rev-parse HEAD)

save_repo multi-tenancy "url=${PARENT}"
save_repo multi-tenancy "branch=master"
save_repo multi-tenancy "commit=${GIT_COMMIT}"