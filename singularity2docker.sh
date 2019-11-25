#! /bin/bash
#
# singularity2docker.sh will convert a singularity image back into a docker
# image.
#
# USAGE: singularity2docker.sh ubuntu.sif
#
# Copyright (C) 2018-2020 Vanessa Sochat.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -o errexit
set -o nounset

usage="USAGE: singularity2docker -n container:new container.simg"

# --- Option processing --------------------------------------------
if [ $# == 0 ] ; then
    echo $usage
    echo "OPTIONS:

          -n|--name: docker container name (container:new)
          --no-cleanup: don't remove build sandbox and Dockerfile within

          "
    exit 1;
fi

container="container:new"
cleanup="true"

while true; do
    case ${1:-} in
        -h|--help|help)
            echo ${usage};
            exit 1;
        ;;
        --name|-n|n)
            shift
            container="${1:-}";
            shift
        ;;
        --no-cleanup)
            cleanup="false";
            shift
        ;;
        -*)
            echo "Beep boop, unknown option: ${1:-}"
            exit 1
        ;;
        *)
            break;
        ;;
    esac
done

image=$1

echo ""
echo "Input Image: ${image}"
echo "Cleanup: ${cleanup}"



################################################################################
### Sanity Checks ##############################################################
################################################################################

echo
echo "1. Checking for software dependencies, Singularity and Docker..."

# The image must exist


if [ ! -e "${image}" ]; then
    echo "Cannot find ${image}, did you give the correct path?"
    exit 1
fi


function is_installed () {
    software=${1}
    if hash ${software} 2>/dev/null; then
        echo "Found ${software} $(${software} --version)"
    else
        echo "${software} must be installed to use singularity2docker.sh"
        exit 1
    fi
}


# Singularity, Docker, and jq must be installed
is_installed singularity
is_installed docker
is_installed jq

################################################################################
### Image Format ###############################################################
################################################################################

# Get the image format
# This is here in case we want to remove Singularity dependency and just work
# with mksquashfs/unsquashfs. Most users that want to convert from Singularity
# will likely have it installed.
# We shouldn't need this as long as older formats are supported to build from
# If we can just use unsquashfs after this we probably don't need Singularity 
# dependency

#libexec=$(dirname $(singularity selftest 2>&1 | grep 'lib' | awk '{print $4}' | sed -e 's@\(.*/singularity\).*@\1@'))
#image_type="$(echo $libexec | awk '{print $1}')/singularity/bin/image-type"
#image_format=$(SINGULARITY_MESSAGELEVEL=0 ${image_type} ${image})
#echo "Found image format ${image_format}"


################################################################################
### Image Sandbox Export #######################################################
################################################################################

echo
echo "2.  Preparing sandbox for export..."
sandbox=$(mktemp -d -t singularity2docker.XXXXXX)
rmdir $sandbox
singularity build --sandbox ${sandbox} ${image}

################################################################################
### Environment/Metadata #######################################################
################################################################################

echo
echo "3.  Exporting metadata..."

# Create temporary Dockerfile

echo 'FROM scratch
ADD . /' > ${sandbox}/Dockerfile

# Environment

echo "ENV LD_LIBRARY_PATH /.singularity.d/libs" >> $sandbox/Dockerfile
echo "ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> $sandbox/Dockerfile


# Labels

# Note: Singularity has not been consistent with output of metadata
# If you have issues here, you might need to tweak the jq parsing below

# Version 3.5 and up has "data" added back in.
data_check=$(singularity inspect -l --json ${image} | jq .data)

# Singularity between 2.5 and 3.5, no data attribute
nesting=".data .attributes .labels"
if [ "${data_check}" == "null" ]; then  
    nesting=".attributes .labels"
fi

entries=$(singularity inspect -l --json ${image} | jq -r "$nesting")
keys=$(echo $entries | jq -r 'keys[]')

for key in ${keys}; do
    value=$(singularity inspect -l --json ${image} | jq -r "$nesting[\"${key}\"]")
    echo "Adding LABEL ${key} ${value}"
    echo "LABEL ${key} \"${value}\"" >> $sandbox/Dockerfile
done

# Command will be to source the environment and run the runscript!

echo "Adding command..."
echo '#!/bin/sh
. /environment
if [ -f "/.singularity.d/actions/run" ]; then
    exec /.singularity.d/actions/run "$@" 
else
    exec /.singularity.d/runscript "$@"
fi' > ${sandbox}/run_singularity2docker.sh
echo "CMD [\"/bin/bash\", \"run_singularity2docker.sh\"]" >> $sandbox/Dockerfile

################################################################################
### Build ######################################################################
################################################################################

echo
echo "4.  Build away, Merrill!"

docker build -t ${container} ${sandbox}
echo "Created container ${container}"
echo "docker inspect ${container}"

if [ "$cleanup" == "true" ]; then
    echo "Cleaning up $sandbox"
    rm -rf ${sandbox}
else
    echo "Sandbox is at $sandbox"
fi
