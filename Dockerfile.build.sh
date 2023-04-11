#!/bin/bash

OUR_IMAGE_SHORT=${OUR_IMAGE_SHORT:-t3rd}
OUR_IMAGE_TAG=${OUR_IMAGE_TAG:-develop}
EXITCODE=0

function usage() {
   echo "Dockerfile.build.sh: Build the Docker image."
   echo "Usage:"
   echo "   /bin/bash  ./$(basename -- $0)"
   echo "   /bin/bash  ./$(basename -- $0) --help"
   echo ""
   echo "More examples:"
   echo "   OUR_IMAGE_TAG=v77.88.99  OUR_IMAGE_SHORT=t3rd     /bin/bash  ./$(basename -- $0)"
   echo "   OUR_IMAGE_TAG=latest     OUR_IMAGE_SHORT=t3rd     /bin/bash  ./$(basename -- $0)"
   echo "   OUR_IMAGE_TAG=develop    OUR_IMAGE_SHORT=develop  /bin/bash  ./$(basename -- $0)"
   echo "   OUR_IMAGE_TAG=test       OUR_IMAGE_SHORT=test     /bin/bash  ./$(basename -- $0)"
   echo
}

if [[ "/ $@ /" =~ " --help " ]]; then
   usage
   exit 0
fi

if ((1)); then
   docker rmi ghcr.io/t3docs/render-documentation:${OUR_IMAGE_TAG}
fi

if ((1)); then
   BUILD_START=$(date '+%s')
   cmd="docker build"
   cmd="$cmd --force-rm=true"
   cmd="$cmd --no-cache=true"
   cmd="$cmd -f ./Dockerfile"
   cmd="$cmd -t ghcr.io/t3docs/render-documentation:${OUR_IMAGE_TAG}"
   if [[ ! -z "$OUR_IMAGE_SHORT" ]]; then
     cmd="$cmd --build-arg OUR_IMAGE_SHORT=\"${OUR_IMAGE_SHORT}\""
   fi
   if [[ ! -z "$OUR_IMAGE_TAG" ]]; then
     cmd="$cmd --build-arg OUR_IMAGE_TAG=\"${OUR_IMAGE_TAG}\""
   fi
   cmd="$cmd ."
   echo $cmd
   eval "$cmd"
   EXITCODE=$?
   BUILD_END=$(date '+%s')
   BUILD_ELAPSED=$(expr $BUILD_END - $BUILD_START)

   if [ $EXITCODE -eq 0 ]; then
      echo Success!
      echo "You may now run:"
      echo "   docker run --rm ghcr.io/t3docs/render-documentation:${OUR_IMAGE_TAG}"
      echo "   eval \"\$(docker run --rm ghcr.io/t3docs/render-documentation:${OUR_IMAGE_TAG} show-shell-commands)\""
   else
      echo Failed
   fi
   echo "building ghcr.io/t3docs/render-documentation:${OUR_IMAGE_TAG} in $BUILD_ELAPSED seconds"
fi
echo Looking for image 'ghcr.io/t3docs:render-documentation:'"${OUR_IMAGE_TAG}"
docker image ls | awk '$1=="ghcr.io/t3docs/render-documentation" && $2=="'${OUR_IMAGE_TAG}'"'
