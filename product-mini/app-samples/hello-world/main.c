/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

int global = 2;
const int nfd = 2;

void loop(int);
void init(uint32_t filenames_offset, int nfd);

int main(int argc, char **argv)
{   
    char *filenames[1] = {"/tmp/myfifo"};

    printf("app: start initialization...\n");

    init((uint32_t)filenames, 1);

    printf("app: start looping...\n");

    loop(5000);

    return 0;
}
