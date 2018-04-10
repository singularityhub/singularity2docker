#! /bin/bash
#
# singularity2docker.sh will convert a singularity image back into a docker
# image.
#
# USAGE: singularity2docker.sh ubuntu.simg
#
# Copyright (C) 2018 Vanessa Sochat.
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

USAGE="USAGE: singularity2docker [-m \"message\"] [options] container.simg"

# --- Option processing --------------------------------------------
if [ $# == 0 ] ; then
    echo $USAGE
    echo "OPTIONS:

          -m: commit message
          -n: docker container name (container:new)
          -e: extra environment variables to add

              "

    exit 1;
fi


message="produced by singularity2docker.sh $(date)"
container="container:new"
while getopts ':hm:n' option; do

  case "$option" in
    h|-h|--help) 
        echo "$USAGE"
        exit 0
    ;;
    --message|m|-m) 
        message="${OPTARG}"
    ;;
    --name|n|-n) 
        container="${OPTARG}"
    ;;
    :) 
        printf "missing argument for -%s\n" "${OPTARG}" >&2
        echo "$usage" >&2
        exit 1
   ;;
   \?) 
        printf "illegal option: -%s\n" "${OPTARG}" >&2
        echo "$usage" >&2
        exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

image=$1

echo ""
echo "Input Image: ${image}"


################################################################################
### Sanity Checks ##############################################################
################################################################################

# The image must exist

if [ ! -e "${image}" ]; then
    echo "Cannot find ${image}, did you give the correct path?"
    exit 1
fi


# Singularity must be installed

if hash singularity 2>/dev/null; then
   echo "Found Singularity $(singularity --version)"
else
   echo "Singularity must be installed to use singularity2docker.sh"
   exit 1
fi

# Docker must be installed

if hash docker 2>/dev/null; then
   echo "Found Docker $(docker --version)"
else
   echo "Docker must be installed to use singularity2docker.sh"
   exit 1
fi


################################################################################
### Image Sandbox Export #######################################################
################################################################################


echo "Preparing build sandbox!"
sandbox=$(mktemp -d -t singularity2docker.XXXXXX)
singularity build --sandbox ${sandbox} ${image}

# Get the image format
# We shouldn't need this as long as older formats are supported to build from

#libexec=$(dirname $(singularity selftest 2>&1 | grep 'lib' | awk '{print $4}' | sed -e 's@\(.*/singularity\).*@\1@'))
#image_type="$(echo $libexec | awk '{print $1}')/singularity/bin/image-type"
#image_format=$(SINGULARITY_MESSAGELEVEL=0 ${image_type} ${image})
#echo "Found image format ${image_format}"

retval=$?

if [ ! retval -eq "0" ]; then
    echo "There was an error building the sandbox, debug
          singularity build --sandbox ${sandbox} ${image}"
    exit 1
fi

################################################################################
### Environment/Metadata #######################################################
################################################################################

# Command will be to source the environment and run the runscript!
CMD="\". /environment && exec /.singularity.d/runscript\""

# Labels
labels=""
keys=$(singularity inspect -l ${image} | jq 'keys[]')
for key in ${keys}; do
    term=".${key}"
    value=$(singularity inspect -l ${image} | jq -r ${term})
    labels="${labels} LABEL ${key} \"${value}\""
    echo "Adding LABEL ${key} ${value}"
done


################################################################################
### Build ######################################################################
################################################################################

layer=$(sudo tar -c ${sandbox} | docker import --change "CMD ${CMD} $labels" --message "${message}" - ${container})
echo "Created layer ${layer}"
