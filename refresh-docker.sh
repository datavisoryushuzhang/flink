#!/bin/bash

function PrintHelp() {
  echo "Usage: sh refresh-docker-all.sh [registry] [tag] [--recompile [project_names]] [--rebuild [project_names]] [--cassandra-relative-path]"
  echo "Options:"
  echo "--recompile        Recompile feature-platform by specify 'fp' and \
  'cassandra' for cassandra project, use comma ',' as delimiter."
  echo "--rebuild          Rebuild docker image by specify a project name, \
  possible value can be 'fp', 'cassandra', 'itest', 'liquibase', 'nacos'. \
  Default is rebuild every docker image, if this argument is specified, ONLY \
  the one specified will be rebuild. "
  echo "--cassandra-relative-path   Specify cassandra relative path from feature platform repo"
}

SCRIPT_PATH="`dirname ${BASH_SOURCE}`"
cd "${SCRIPT_PATH}"

if [ $# -lt 2 ]; then
  echo "error: too few arguments"
	PrintHelp
	exit 2
fi

CURRENT_PATH=$(pwd)

# Required args
DOCKER_REPOSITORY=`expr "$1" : '\([^\/]*\/[^\/]*\)'`
shift
TAG=$1
shift
SUFFIX=""
FLINK_HOME=${CURRENT_PATH%"$SUFFIX"}
REBUILD=
RECOMPILE=
ARGS=

set -e

while [ "$1" != "" ]; do

    case "$1" in
        --rebuild)        shift
                          REBUILD="$1"
                          ;;
        --recompile)      shift
                          RECOMPILE="$1"
                          ;;
        --help)           PrintHelp
                          exit 0
                          ;;
        *)                >&2 echo "error: invalid option: '$1'"
                          PrintHelp
                          exit 3
    esac
    # Shift all the parameters down by one
    shift

done

if [ -z "${FLINK_HOME}" ]; then
    echo "FLINK_HOME must be set!"
    exit 1
fi

if [ -z "${DOCKER_FILE_HOME}" ]; then
    mkdir -p /tmp/docker
    export DOCKER_FILE_HOME=/tmp/docker
fi



# remove leading whitespace characters
ARGS="${ARGS#"${ARGS%%[![:space:]]*}"}"

#clean up old files
rm -rf $DOCKER_FILE_HOME/*

# Build most recent flink
if [ -n $RECOMPILE ]; then
  RECOMPILE=(${RECOMPILE//,/ })
  CURRENT_PATH=$(pwd)
  for project in "${RECOMPILE[@]}"; do

    if [ "${project}" == "flink" ]; then
      echo "=========== Recompile flink project ==========="
      cd $FLINK_HOME
      mvn clean install -DskipTests -Dfast -T 1C
    fi

  done
  cd $CURRENT_PATH
fi

DEFAULT="flink"
REBUILD=${REBUILD:=$DEFAULT}
REBUILD=(${REBUILD//,/ })

echo $DOCKER_REPOSITORY
for project in "${REBUILD[@]}"; do
  # For flink
  if [ "${project}" == "flink" ]; then
    mkdir -p "${DOCKER_FILE_HOME}/flink/dist"
    cp -r "${FLINK_HOME}/build-target/." "${DOCKER_FILE_HOME}/flink/dist"
    cd "${DOCKER_FILE_HOME}/flink/dist"
    tar -czvf flink.tar.gz .
    cd -
    cp -r "${FLINK_HOME}/flink-docker/." "${DOCKER_FILE_HOME}/flink"
    ./build_docker_image.sh -t $TAG -r $DOCKER_REPOSITORY/flink --path "${DOCKER_FILE_HOME}/flink/." ${ARGS}
  fi
done
