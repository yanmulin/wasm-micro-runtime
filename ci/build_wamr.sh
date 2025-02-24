#!/usr/bin/env bash

# Copyright (C) 2019 Intel Corporation.  All rights reserved.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

readonly CURRENT_PATH=$(dirname "$(realpath "$0")")
readonly ROOT=$(realpath "${CURRENT_PATH}/..")
readonly VARIANT=$(lsb_release -c | awk '{print $2}')

docker build \
  --build-arg VARIANT=${VARIANT} \
  --memory=4G --cpu-quota=50000 \
  -t wamr_dev_${VARIANT}:0.1 -f "${CURRENT_PATH}"/Dockerfile "${CURRENT_PATH}" &&
  docker run --rm -it \
    --cpus=".5" \
    --memory=4G \
    --name wamr_build_env \
    --mount type=bind,src="${ROOT}",dst=/workspace \
    wamr_dev_${VARIANT}:0.1 \
    /bin/bash -c "\
      pwd \
      && pushd product-mini/platforms/linux \
      && rm -rf build \
      && mkdir build  \
      && pushd build \
      && cmake .. \
      && make \
      && popd \
      && popd \
      && echo 'Copying the binary ...' \
      && rm -rf build_out \
      && mkdir build_out \
      && cp product-mini/platforms/linux/build/iwasm build_out/iwasm"
