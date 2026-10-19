/* Fixed non-arm64e ARM64 saved-state ABI, consumed by the ELF switch code.
 * C compilation checks these offsets against XNU's actual context layout. */
#ifndef XNU_USERMODE_CONTEXT_H
#define XNU_USERMODE_CONTEXT_H
#define HOST_CTX_X19 0
#define HOST_CTX_FP 80
#define HOST_CTX_LR 88
#define HOST_CTX_SP 96
#define HOST_CTX_USER_PC 104
#define HOST_CTX_D8 112
#define HOST_CTX_FPCR 176
#ifndef __ASSEMBLER__
#include <stddef.h>
#include <mach/arm/thread_status.h>
_Static_assert(offsetof(arm_kernel_context_t, ss.x[0]) == HOST_CTX_X19, "kernel x19 ABI");
_Static_assert(offsetof(arm_kernel_context_t, ss.fp) == HOST_CTX_FP, "kernel fp ABI");
_Static_assert(offsetof(arm_kernel_context_t, ss.lr) == HOST_CTX_LR, "kernel lr ABI");
_Static_assert(offsetof(arm_kernel_context_t, ss.sp) == HOST_CTX_SP, "kernel sp ABI");
_Static_assert(offsetof(arm_kernel_context_t, ss.pc_was_in_userspace) == HOST_CTX_USER_PC, "kernel PC origin ABI");
_Static_assert(offsetof(arm_kernel_context_t, ns.d[0]) == HOST_CTX_D8, "kernel d8 ABI");
_Static_assert(offsetof(arm_kernel_context_t, ns.fpcr) == HOST_CTX_FPCR, "kernel FPCR ABI");
#endif
#endif
