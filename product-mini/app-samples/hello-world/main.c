/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include <stdio.h>
#include <stdlib.h>

int global = 2;

void func();

int foo(int x) {
    int local = 0;
    printf("entering foo(x=%d), local=%d, global=%d\n", x, local, global);
    local ++;
    func();
    printf("exiting foo(x=%d), local=%d, global=%d\n", x, local, global);
    return local;
}

void resume() {
    printf("resume\n");
}

int
main(int argc, char **argv)
{
    printf("entering main(), global=%d\n", global);
    global ++;
    foo(1);
    printf("exiting main(), global=%d\n", global);
    return 0;
}
