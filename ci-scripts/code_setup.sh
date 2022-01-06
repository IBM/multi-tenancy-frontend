#!/usr/bin/env bash

source "${ONE_PIPELINE_PATH}"/tools/get_repo_params

APP_TOKEN_PATH="./app-token"
read -r APP_REPO_NAME APP_REPO_OWNER APP_SCM_TYPE APP_API_URL < <(get_repo_params "$(get_env APP_REPO)" "$APP_TOKEN_PATH")

if [[ $APP_SCM_TYPE == "gitlab" ]]; then
  curl --location --request PUT "${APP_API_URL}/projects/${OWNER}%2F${REPO}/" \
    --header "PRIVATE-TOKEN: $(cat $APP_TOKEN_PATH)" \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "only_allow_merge_if_pipeline_succeeds": true
    }'
else
  curl -H "Authorization: Bearer $(cat ${APP_TOKEN_PATH})" ${APP_API_URL}/repos/${APP_REPO_OWNER}/${APP_REPO_NAME}/branches/master/protection \
    -XPUT -d '{"required_pull_request_reviews":{"dismiss_stale_reviews":true},"required_status_checks":{"strict":true,"contexts":["tekton/code-branch-protection","tekton/code-unit-tests","tekton/code-cis-check","tekton/code-vulnerability-scan","tekton/code-detect-secrets"]},"enforce_admins":null,"restrictions":null}'
fi

GITLAB_TOKEN=$(cat "$WORKSPACE/secrets/git-token")
GITLAB_URL="$(get_env SCM_API_URL)"
OWNER=$(jq -r '.services[] | select(.toolchain_binding.name=="app-repo") | .parameters.owner_id' /toolchain/toolchain.json)
REPO=$(jq -r '.services[] | select(.toolchain_binding.name=="app-repo") | .parameters.repo_name' /toolchain/toolchain.json)

#############################################

echo "ci-cd-scripts/code_setup.sh"
export PARENT=$(get_env "multi-tenancy")
echo $PARENT

cd ..
git clone $PARENT

cd multi-tenancy
GIT_COMMIT=$(git rev-parse HEAD)

save_repo multi-tenancy "url=${PARENT}"
save_repo multi-tenancy "branch=main"
save_repo multi-tenancy "path=multi-tenancy"
save_repo multi-tenancy "commit=${GIT_COMMIT}"
