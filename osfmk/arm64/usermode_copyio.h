#ifndef XNU_ARM64_USERMODE_COPYIO_H
#define XNU_ARM64_USERMODE_COPYIO_H
#include <mach/vm_types.h>
#include <stdint.h>

/* Called only after copyio.c's original address/tag/zone/alignment checks.
 * Kernel-to-kernel copies retain the original copyin_kern/copyout_kern path. */
int xnu_usermode_copyin(vm_map_offset_t user, void *kernel, vm_size_t bytes);
int xnu_usermode_copyout(const void *kernel, vm_map_offset_t user, vm_size_t bytes);
int xnu_usermode_copyinstr(vm_map_offset_t user, char *kernel, vm_size_t maximum,
    vm_size_t *actual);
int xnu_usermode_copy_atomic(vm_map_offset_t user, void *value,
    unsigned int bytes, int write);
int xnu_usermode_wait32(vm_map_offset_t user, uint32_t expected);
#endif
