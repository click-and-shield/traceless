#!/usr/bin/env bash
#
# Start a container used to build the ISO image.

# Turn on "strict mode".
# - See http://redsymbol.net/articles/unofficial-bash-strict-mode/.
# - See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html#The-Set-Builtin
#
# -e: exit immediately if a pipeline, which may consist of a single simple command, a list,
#     or a compound command returns a non-zero status. 
# -u: treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as
#     an error when performing parameter expansion. An error message will be written to the
#     standard error, and a non-interactive shell will exit.
# -o pipefail: if set, the return value of a pipeline is the value of the last (rightmost)
#              command to exit with a non-zero status, or zero if all commands in the pipeline
#              exit successfully.
set -eu -o pipefail

__FILE_NAME__="${BASH_SOURCE[0]}"
while [ -h "${__FILE_NAME__}" ] ; do __FILE_NAME__="$(readlink "${__FILE_NAME__}")"; done
__DIR__="$( cd -P "$( dirname "${__FILE_NAME__}" )" && pwd )"
declare -r __DIR__
declare -r BUILD_DIR="${__DIR__}/../live-build"
declare -r CACHE_DIR="${__DIR__}/.apt-cache"

echo "BUILD_DIR: ${BUILD_DIR}"
echo "CACHE_DIR: ${CACHE_DIR}"

echo "--- S/Docker info ---"
docker context show
echo "${DOCKER_HOST:-<non définie>}"
docker info --format 'Docker host: {{.Name}}'
echo "--- E/Docker info ---"

if [ ! -d  "${BUILD_DIR}" ]; then
  echo "Create ${BUILD_DIR}"
  mkdir -p "${BUILD_DIR}"
fi

if [ ! -d  "${CACHE_DIR}" ]; then
  echo "Create ${CACHE_DIR}"
  mkdir -p "${CACHE_DIR}"
fi


# Copy the files that will be used to build the ISO image.
echo "Copy \"${__DIR__}/ressources/*\" into \"${BUILD_DIR}/\""
cp -R "${__DIR__}"/ressources/* "${BUILD_DIR}/"
find "${BUILD_DIR}/" -type f -name "*.sh" -exec dos2unix {} \;
find "${BUILD_DIR}/" -type f -name "*.sh" -exec chmod +x {} \;

ls -la "${BUILD_DIR}"
ls -la "${CACHE_DIR}"

echo "Working directory: \"${BUILD_DIR}\""

docker run \
  --rm \
  -it \
  --privileged \
  -v "${BUILD_DIR}:/workspace" \
  -v "${CACHE_DIR}:/var/cache/apt" \
  debian-trixie

