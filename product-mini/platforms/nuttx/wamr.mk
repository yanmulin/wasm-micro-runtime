# Copyright (C) 2019 Intel Corporation.  All rights reserved.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

CORE_ROOT := wamr/core
IWASM_ROOT := wamr/core/iwasm
SHARED_ROOT := wamr/core/shared

ifeq ($(CONFIG_ARCH_ARMV7A),y)
WAMR_BUILD_TARGET := THUMBV7A
else ifeq ($(CONFIG_ARCH_ARMV7M),y)
WAMR_BUILD_TARGET := THUMBV7EM
else ifeq ($(CONFIG_ARCH_ARMV8M),y)
WAMR_BUILD_TARGET := THUMBV8M
else ifeq ($(CONFIG_ARCH_X86),y)
WAMR_BUILD_TARGET := X86_32
else ifeq ($(CONFIG_ARCH_X86_64),y)
WAMR_BUILD_TARGET := X86_64
else ifeq ($(CONFIG_ARCH_XTENSA),y)
WAMR_BUILD_TARGET := XTENSA
else ifeq ($(CONFIG_ARCH_RV64GC),y)
WAMR_BUILD_TARGET := RISCV64
else ifeq ($(CONFIG_ARCH_RV32IM),y)
WAMR_BUILD_TARGET := RISCV32
else ifeq ($(CONFIG_ARCH_SIM),y)
ifeq ($(CONFIG_SIM_M32),y)
WAMR_BUILD_TARGET := X86_32
else
WAMR_BUILD_TARGET := X86_64
endif
ifeq ($(CONFIG_HOST_MACOS),y)
# Note: invokeNative_em64.s needs BH_PLATFORM_DARWIN
AFLAGS += -DBH_PLATFORM_DARWIN
endif
endif

WAMR_BUILD_PLATFORM := nuttx

ifeq ($(WAMR_BUILD_TARGET), X86_32)
  CFLAGS += -DBUILD_TARGET_X86_32
  INVOKE_NATIVE := invokeNative_ia32.s
  AOT_RELOC := aot_reloc_x86_32.c
else ifeq ($(WAMR_BUILD_TARGET), X86_64)
  CFLAGS += -DBUILD_TARGET_X86_64
  INVOKE_NATIVE := invokeNative_em64.s
  AOT_RELOC := aot_reloc_x86_64.c
else ifeq ($(findstring ARM,$(WAMR_BUILD_TARGET)), ARM)
  CFLAGS += -DBUILD_TARGET_ARM
  CFLAGS += -DBUILD_TARGET=\"$(WAMR_BUILD_TARGET)\"
  INVOKE_NATIVE := invokeNative_arm.s
  AOT_RELOC := aot_reloc_arm.c
else ifeq ($(findstring THUMB,$(WAMR_BUILD_TARGET)), THUMB)
  CFLAGS += -DBUILD_TARGET=\"$(WAMR_BUILD_TARGET)\"
  ifeq ($(CONFIG_ARCH_FPU),y)
  CFLAGS += -DBUILD_TARGET_THUMB_VFP
  INVOKE_NATIVE := invokeNative_thumb_vfp.s
  else
  CFLAGS += -DBUILD_TARGET_THUMB
  INVOKE_NATIVE := invokeNative_thumb.s
  endif
  AOT_RELOC := aot_reloc_thumb.c
else ifeq (${WAMR_BUILD_TARGET}, MIPS)
  CFLAGS += -DBUILD_TARGET_MIPS
  INVOKE_NATIVE := invokeNative_mips.s
  AOT_RELOC := aot_reloc_mips.c
else ifeq (${WAMR_BUILD_TARGET}, XTENSA)
  CFLAGS += -DBUILD_TARGET_XTENSA
  INVOKE_NATIVE := invokeNative_xtensa.s
  AOT_RELOC := aot_reloc_xtensa.c
else ifeq (${WAMR_BUILD_TARGET}, RISCV64)

ifeq (${CONFIG_ARCH_FPU},y)
  $(error riscv64 lp64f is unsupported)
else ifeq (${CONFIG_ARCH_DPFPU}, y)
  CFLAGS += -DBUILD_TARGET_RISCV64_LP64D
else
  CFLAGS += -DBUILD_TARGET_RISCV64_LP64
endif
  INVOKE_NATIVE += invokeNative_riscv.S

  AOT_RELOC := aot_reloc_riscv.c

else ifeq (${WAMR_BUILD_TARGET}, RISCV32)

ifeq (${CONFIG_ARCH_FPU}, y)
  $(error riscv32 ilp32f is unsupported)
else ifeq (${CONFIG_ARCH_DPFPU}, y)
  CFLAGS += -DBUILD_TARGET_RISCV32_ILP32D
else
  CFLAGS += -DBUILD_TARGET_RISCV32_ILP32
endif

  INVOKE_NATIVE += invokeNative_riscv.S
  AOT_RELOC := aot_reloc_riscv.c

else
  $(error Build target is unsupported)
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_LOG),y)
CFLAGS += -DWASM_ENABLE_LOG=1
else
CFLAGS += -DWASM_ENABLE_LOG=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_AOT),y)
CFLAGS += -I$(IWASM_ROOT)/aot
CFLAGS += -DWASM_ENABLE_AOT=1
CSRCS += aot_loader.c \
         $(AOT_RELOC) \
         aot_intrinsic.c \
         aot_runtime.c
else
CFLAGS += -DWASM_ENABLE_AOT=0
endif

CFLAGS += -DWASM_ENABLE_INTERP=1
CSRCS += wasm_runtime.c

ifeq ($(CONFIG_INTERPRETERS_WAMR_FAST),y)
CFLAGS += -DWASM_ENABLE_FAST_INTERP=1
CSRCS += wasm_interp_fast.c
else
CSRCS += wasm_interp_classic.c
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_LIBC_BUILTIN),y)
CFLAGS += -DWASM_ENABLE_LIBC_BUILTIN=1
else
CFLAGS += -DWASM_ENABLE_LIBC_BUILTIN=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_MULTI_MODULE),y)
CFLAGS += -DWASM_ENABLE_MULTI_MODULE=1
else
CFLAGS += -DWASM_ENABLE_MULTI_MODULE=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_THREAD_MGR),y)
CFLAGS += -DWASM_ENABLE_THREAD_MGR=1
CSRCS += thread_manager.c
VPATH += $(IWASM_ROOT)/libraries/thread-mgr
else
CFLAGS += -DWASM_ENABLE_THREAD_MGR=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_LIB_PTHREAD),y)
CFLAGS += -DWASM_ENABLE_LIB_PTHREAD=1
CSRCS += lib_pthread_wrapper.c
else
CFLAGS += -DWASM_ENABLE_LIB_PTHREAD=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_MINILOADER),y)
CFLAGS += -DWASM_ENABLE_MINI_LOADER=1
CSRCS += wasm_mini_loader.c
else
CFLAGS += -DWASM_ENABLE_MINI_LOADER=0
CSRCS += wasm_loader.c
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_DISABLE_HW_BOUND_CHECK),y)
CFLAGS += -DWASM_DISABLE_HW_BOUND_CHECK=1
else
CFLAGS += -DWASM_DISABLE_HW_BOUND_CHECK=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_CUSTOM_NAME_SECTIONS),y)
CFLAGS += -DWASM_ENABLE_CUSTOM_NAME_SECTION=1
else
CFLAGS += -DWASM_ENABLE_CUSTOM_NAME_SECTION=0
endif

ifeq ($(CONFIG_INTERPRETERS_WAMR_GLOBAL_HEAP_POOL),y)
CFLAGS += -DWASM_ENABLE_GLOBAL_HEAP_POOL=1
CFLAGS += -DWASM_GLOBAL_HEAP_SIZE=$(CONFIG_INTERPRETERS_WAMR_GLOBAL_HEAP_POOL_SIZE)
else
CFLAGS += -DWASM_ENABLE_GLOBAL_HEAP_POOL=0
endif

CFLAGS += -Wno-strict-prototypes -Wno-shadow -Wno-unused-variable
CFLAGS += -Wno-int-conversion -Wno-implicit-function-declaration

CFLAGS += -I${CORE_ROOT} \
          -I${IWASM_ROOT}/include \
          -I${IWASM_ROOT}/interpreter \
          -I${IWASM_ROOT}/common \
          -I${IWASM_ROOT}/libraries/thread-mgr \
          -I${SHARED_ROOT}/include \
          -I${SHARED_ROOT}/platform/include \
          -I${SHARED_ROOT}/utils \
          -I${SHARED_ROOT}/utils/uncommon \
          -I${SHARED_ROOT}/mem-alloc \
          -I${SHARED_ROOT}/platform/nuttx

ifeq ($(WAMR_BUILD_INTERP), 1)
CFLAGS += -I$(IWASM_ROOT)/interpreter
endif

CSRCS += nuttx_platform.c \
         posix_thread.c \
         posix_time.c \
         mem_alloc.c \
         ems_kfc.c \
         ems_alloc.c \
         ems_hmu.c \
         bh_assert.c \
         bh_common.c \
         bh_hashmap.c \
         bh_list.c \
         bh_log.c \
         bh_queue.c \
         bh_vector.c \
         bh_read_file.c \
         runtime_timer.c \
         libc_builtin_wrapper.c \
         wasm_application.c \
         wasm_runtime_common.c \
         wasm_native.c \
         wasm_exec_env.c \
         wasm_memory.c \
         wasm_c_api.c

ASRCS += $(INVOKE_NATIVE)

VPATH += $(SHARED_ROOT)/platform/nuttx
VPATH += $(SHARED_ROOT)/platform/common/posix
VPATH += $(SHARED_ROOT)/mem-alloc
VPATH += $(SHARED_ROOT)/mem-alloc/ems
VPATH += $(SHARED_ROOT)/utils
VPATH += $(SHARED_ROOT)/utils/uncommon
VPATH += $(IWASM_ROOT)/common
VPATH += $(IWASM_ROOT)/interpreter
VPATH += $(IWASM_ROOT)/libraries
VPATH += $(IWASM_ROOT)/libraries/libc-builtin
VPATH += $(IWASM_ROOT)/libraries/lib-pthread
VPATH += $(IWASM_ROOT)/common/arch
VPATH += $(IWASM_ROOT)/aot
VPATH += $(IWASM_ROOT)/aot/arch
