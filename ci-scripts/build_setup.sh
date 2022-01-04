#!/usr/bin/env bash

set -euo pipefail

if [[ "${PIPELINE_DEBUG:-0}" == 1 ]]; then
  set -x
  trap env EXIT
fi

while read -r key; do
  url=$(load_repo $key url)
done < <(list_repos)

#example: https://github.com/IBM/multi-tenancy/blob/main/configuration/global.json
CONFIG_FILE="../multi-tenancy/configuration/global.json"

IBM_CLOUD_RESOURCE_GROUP=$(cat ./$CONFIG_FILE | jq '.IBM_CLOUD.RESOURCE_GROUP' | sed 's/"//g')
IBM_CLOUD_REGION=$(cat ./$CONFIG_FILE | jq '.IBM_CLOUD.REGION' | sed 's/"//g')
REGISTRY_NAMESPACE=$(cat ./$CONFIG_FILE | jq '.REGISTRY.NAMESPACE' | sed 's/"//g')
REGISTRY_TAG=$(cat ./$CONFIG_FILE | jq '.REGISTRY.TAG' | sed 's/"//g')
REGISTRY_URL=$(cat ./$CONFIG_FILE | jq '.REGISTRY.URL' | sed 's/"//g')
REGISTRY_SECRET_NAME=$(cat ./$CONFIG_FILE | jq '.REGISTRY.SECRET_NAME' | sed 's/"//g')
IMAGES_NAME_BACKEND=$(cat ./$CONFIG_FILE | jq '.IMAGES.NAME_BACKEND' | sed 's/"//g')
IMAGES_NAME_FRONTEND=$(cat ./$CONFIG_FILE | jq '.IMAGES.NAME_FRONTEND' | sed 's/"//g')

IMAGE="$REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGES_NAME_FRONTEND:$REGISTRY_TAG"
docker login -u iamapikey --password-stdin "$REGISTRY_URL" < /config/api-key

ibmcloud config --check-version false
ibmcloud login --apikey @/config/api-key -r "$IBM_CLOUD_REGION"
ibmcloud target -g $IBM_CLOUD_RESOURCE_GROUP

ibmcloud cr login 

NS=$( ibmcloud cr namespaces | sed 's/ *$//' | grep -x "${REGISTRY_NAMESPACE}" ||: )

if [ -z "${NS}" ]; then
    echo "Registry namespace ${REGISTRY_NAMESPACE} not found"
    ibmcloud cr namespace-add "${REGISTRY_NAMESPACE}"
    echo "Registry namespace ${REGISTRY_NAMESPACE} created."
else
    echo "Registry namespace ${REGISTRY_NAMESPACE} found."
fi
