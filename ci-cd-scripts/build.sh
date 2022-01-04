#!/usr/bin/env bash

set -euo pipefail

docker build -t "${IMAGE}" .
docker push "${IMAGE}"

DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE" | awk -F@ '{print $2}')"
echo -n "$DIGEST" > ../image-digest
echo -n "$IMAGE" > ../image

if which save_artifact >/dev/null; then
  save_artifact app-image type=image "name=${IMAGE}" "digest=${DIGEST}"
fi
