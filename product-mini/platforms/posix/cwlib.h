#ifndef _CWLIB_H
#define _CWLIB_H

#include "wasm_export.h"
#include "wasm_runtime_common.h"

void init(wasm_exec_env_t exec_env, uint32 filenames_offset, int nfd);
void loop(wasm_exec_env_t exec_env, int sleep_ms);

#endif