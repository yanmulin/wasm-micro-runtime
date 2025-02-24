#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wasm_c_api.h"

#define own

#define MIN(x, y) ((x)<(y) ? (x) : (y))

wasm_memory_t* get_export_memory(const wasm_extern_vec_t* exports, size_t i) {
  if (exports->size <= i || !wasm_extern_as_memory(exports->data[i])) {
    printf("> Error accessing memory export %zu!\n", i);
    exit(1);
  }
  return wasm_extern_as_memory(exports->data[i]);
}

wasm_func_t* get_export_func(const wasm_extern_vec_t* exports, size_t i) {
  if (exports->size <= i || !wasm_extern_as_func(exports->data[i])) {
    printf("> Error accessing function export %zu!\n", i);
    exit(1);
  }
  return wasm_extern_as_func(exports->data[i]);
}

void func_call(wasm_func_t* func, int i, wasm_val_t args[], wasm_val_vec_t* result_vec) {
  wasm_val_vec_t args_vec;
  if (args) wasm_val_vec_new(&args_vec, i, args);
  if (wasm_func_call(func, args ? &args_vec : NULL, result_vec)) {
    printf("> Error on result\n");
    exit(1);
  }
}


void load(const char *filename, wasm_memory_t *memory) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        printf("> Error opening dump file!\n");
        exit(1);
    }

    size_t n = wasm_memory_data_size(memory);
    fseek(file, 0L, SEEK_END);
    size_t file_size = ftell(file);
    fseek(file, 0L, SEEK_SET);
    fread((void*)wasm_memory_data(memory), sizeof(byte_t), MIN(n, file_size), file);

    fclose(file);

}


int main(int argc, const char *argv[]) {
    printf("Initializing...\n");
    wasm_engine_t* engine = wasm_engine_new();
    wasm_store_t* store = wasm_store_new(engine);

    #if WASM_ENABLE_AOT != 0 && WASM_ENABLE_INTERP == 0
    return 0;
    #endif

    FILE* file = fopen("memory.wasm", "rb");

    if (!file) {
    printf("> Error loading module!\n");
    return 1;
  }
  fseek(file, 0L, SEEK_END);
  size_t file_size = ftell(file);
  fseek(file, 0L, SEEK_SET);
  wasm_byte_vec_t binary;
  wasm_byte_vec_new_uninitialized(&binary, file_size);
  if (fread(binary.data, file_size, 1, file) != 1) {
    printf("> Error loading module!\n");
    fclose(file);
    return 1;
  }
  fclose(file);

  // Compile.
  printf("Compiling module...\n");
  own wasm_module_t* module = wasm_module_new(store, &binary);
  if (!module) {
    printf("> Error compiling module!\n");
    return 1;
  }

  wasm_byte_vec_delete(&binary);

  // Instantiate.
  printf("Instantiating module...\n");
  own wasm_instance_t* instance =
    wasm_instance_new_with_args(store, module, NULL, NULL, KILOBYTE(8), 0);
  if (!instance) {
    printf("> Error instantiating module!\n");
    return 1;
  }

  // Extract export.
  printf("Extracting exports...\n");
  own wasm_extern_vec_t exports;
  wasm_instance_exports(instance, &exports);
  size_t i = 0;
  wasm_memory_t* memory = get_export_memory(&exports, i++);
  get_export_func(&exports, i++); // size func
  wasm_func_t* load_func = get_export_func(&exports, i++);
  get_export_func(&exports, i++); // store func

  wasm_module_delete(module);

  if (!memory || !wasm_memory_data(memory)) {
    printf("> Error getting memory!\n");
    wasm_extern_vec_delete(&exports);
    wasm_instance_delete(instance);
    wasm_store_delete(store);
    wasm_engine_delete(engine);
    return 1;
  }

  printf("Loading memory...\n");
  load("mem.core", memory);

  printf("Accessing memory...\n");
  wasm_val_vec_t result_vec;
  wasm_val_vec_new(&result_vec, 1, (wasm_val_t []){ WASM_INIT_VAL });
  func_call(load_func, 1, (wasm_val_t[]){ WASM_I32_VAL(0x0) }, &result_vec);
  printf("load(0x0) -> 0x%x\n", result_vec.data[0].of.i32);
  func_call(load_func, 1, (wasm_val_t[]){ WASM_I32_VAL(0x1002)}, &result_vec);
  printf("load(0x1002) -> 0x%x\n", result_vec.data[0].of.i32);


  return 0;
}