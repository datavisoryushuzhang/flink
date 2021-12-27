#!/bin/bash


# ================================================================
# === FUNCTIONS
# ================================================================

function PrintHelp() {
cat << EOF
usage:         build_docker_image.sh [options...]
options:
  -t --tag      The tag name you want to tag on this image
  -r --repo     The repo name on Datavisor global docker registry
  -u --username The username used to login to global docker registry
  -p --password The password used to login to global docker registry
  -b --branch   The code branch used for this docker image
  -c --codehash The code commit hash for this docker image
  --path        The path to your DockerFile
  --latest      Tag this image as latest
  --push        Push this image to remote registry
  --cloud       Build this image for remote registry, default is local
EOF
}


set -e
# Three args are required
if [ $# -lt 6 ]; then
	echo "error: too few arguments"
	PrintHelp
	exit 2
fi

DOCKER_TAG_NAME="Master"
DOCKER_REPO_NAME=
DOCKER_FILE_PATH=
REGISTRY_USERNAME=
REGISTRY_PASSWORD=
CODE_BRANCH=
CODE_HASH=
LATEST="false"
PUSH="false"
CLOUD="false"

# Loop through the command-line options
while [ "$1" != "" ]; do

    case "$1" in
        -t | --tag)   shift
                      DOCKER_TAG_NAME="$1"
                      ;;
        -r | --repo)  shift
                      DOCKER_REPO_NAME="$1"
                      ;;
        -p | --password)  shift
                      REGISTRY_PASSWORD="$1"
                      ;;
        -u | --username)  shift
                      REGISTRY_USERNAME="$1"
                      ;;
        -b | --branch)  shift
                      CODE_BRANCH="$1"
                      ;;
        -c | --codehash)  shift
                      CODE_HASH="$1"
                      ;;
        --path)       shift
                      DOCKER_FILE_PATH="$1"
                      ;;
        --cassandra-version)       shift
                      CASSANDRA_VERSION="$1"
                      ;;
        --latest)     LATEST="true"
                      ;;
        --push)       PUSH="true"
                      ;;
        --cloud)      CLOUD="true"
                      ;;
        --help)       PrintHelp
                      exit 0
                      ;;
        *)            >&2 echo "error: invalid option: '$1'"
                      PrintHelp
                      exit 3
    esac

    # Shift all the parameters down by one
    shift
done

echo $DOCKER_REPO_NAME
echo $DOCKER_TAG_NAME
echo $DOCKER_FILE_PATH
echo '---------------------------'

REMOTE_REPO_URL='docker-registry.dv-api.com/cloud'

if [[ -z "$CASSANDRA_VERSION" ]]; then
  docker build -t "$DOCKER_REPO_NAME:$DOCKER_TAG_NAME" $DOCKER_FILE_PATH
else
  docker build -t "$DOCKER_REPO_NAME:$DOCKER_TAG_NAME" $DOCKER_FILE_PATH --build-arg CASSANDRA_JAR_VERSION=$CASSANDRA_VERSION
fi

echo "${DOCKER_REPO_NAME}:${DOCKER_TAG_NAME} image is built"

# Login to ECR, and make sure you have credentials before building the docker image
# A way to have credentials is to set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION in env
if [ $CLOUD == "true" ]; then
  docker login "${REMOTE_REPO_URL}" -u "${REGISTRY_USERNAME}" -p "${REGISTRY_PASSWORD}"
  docker tag $DOCKER_REPO_NAME:$DOCKER_TAG_NAME $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$DOCKER_TAG_NAME
  echo "Tag image as ${REMOTE_REPO_URL}/${DOCKER_REPO_NAME}:${DOCKER_TAG_NAME}"
  if [ $PUSH == "true" ]; then
    docker tag $DOCKER_REPO_NAME:$DOCKER_TAG_NAME $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$CODE_BRANCH
    docker tag $DOCKER_REPO_NAME:$DOCKER_TAG_NAME $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$CODE_HASH
    docker push $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$CODE_HASH
    echo "Pushed image $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$CODE_HASH to docker registry"
  fi

  if [ $LATEST == "true" ]; then
    docker tag $REMOTE_REPO_URL/$DOCKER_REPO_NAME:$DOCKER_TAG_NAME "$REMOTE_REPO_URL/$DOCKER_REPO_NAME:latest"
    echo "Tag image as $REMOTE_REPO_URL/$DOCKER_REPO_NAME:latest"
    if [ $PUSH == "true" ]; then
      docker push "$REMOTE_REPO_URL/$DOCKER_REPO_NAME:latest"
      echo "Push image $REMOTE_REPO_URL/$DOCKER_REPO_NAME:latest to docker registry"
    fi
  fi
else
  docker tag "$DOCKER_REPO_NAME:$DOCKER_TAG_NAME" "$DOCKER_REPO_NAME:localtest"
fi


